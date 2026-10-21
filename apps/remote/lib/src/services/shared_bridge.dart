import 'dart:async';

import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'devices.dart';
import 'tv_session.dart';

/// Hands the selected TV and its live state to the iOS widgets, Control
/// Center controls, Siri shortcuts and the Live Activity, which run outside
/// the Flutter app (ios/Runner/SharedBridge.swift).
abstract class SharedBridge {
  Future<void> setTv(SavedTv tv, ClientIdentity identity);
  Future<void> clearTv();
  Future<void> setApps(List<RemoteApp> apps);
  Future<void> updateStatus(SharedStatusData status);
  Future<void> setLiveActivity(bool enabled);
}

@immutable
class SharedStatusData {
  const SharedStatusData({
    required this.connected,
    required this.appLabel,
    this.title,
    this.volume,
    this.volumeMax,
    this.muted = false,
  });

  final bool connected;
  final String appLabel;
  final String? title;
  final int? volume;
  final int? volumeMax;
  final bool muted;

  Map<String, Object?> toMap() => {
        'connected': connected,
        'appLabel': appLabel,
        'title': title,
        'volume': volume,
        'volumeMax': volumeMax,
        'muted': muted,
      };

  @override
  bool operator ==(Object other) =>
      other is SharedStatusData &&
      other.connected == connected &&
      other.appLabel == appLabel &&
      other.title == title &&
      other.volume == volume &&
      other.volumeMax == volumeMax &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(connected, appLabel, title, volume, volumeMax, muted);
}

/// The real bridge (iOS only; a no-op elsewhere and when the native side is
/// missing, e.g. the macOS build).
class MethodChannelSharedBridge implements SharedBridge {
  MethodChannelSharedBridge([this._channel = const MethodChannel('tvcontrol/shared')]);
  final MethodChannel _channel;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _call(String method, [Object? args]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<Object?>(method, args);
    } on MissingPluginException {
      // Older build without the extension.
    } on PlatformException {
      // Widgets are best-effort; the app keeps working.
    }
  }

  @override
  Future<void> setTv(SavedTv tv, ClientIdentity identity) => _call('setTv', {
        'id': tv.id,
        'name': tv.name,
        'host': tv.host,
        'mac': tv.mac,
        'certificatePem': identity.certificatePem,
        'privateKeyPem': identity.privateKeyPem,
      });

  @override
  Future<void> clearTv() => _call('clearTv');

  @override
  Future<void> setApps(List<RemoteApp> apps) => _call('setApps', {
        'apps': [
          for (final a in apps) {'package': a.package, 'label': a.label, 'link': a.link},
        ],
      });

  @override
  Future<void> updateStatus(SharedStatusData status) => _call('updateStatus', status.toMap());

  @override
  Future<void> setLiveActivity(bool enabled) => _call('setLiveActivity', {'enabled': enabled});
}

class NoopSharedBridge implements SharedBridge {
  const NoopSharedBridge();
  @override
  Future<void> setTv(SavedTv tv, ClientIdentity identity) async {}
  @override
  Future<void> clearTv() async {}
  @override
  Future<void> setApps(List<RemoteApp> apps) async {}
  @override
  Future<void> updateStatus(SharedStatusData status) async {}
  @override
  Future<void> setLiveActivity(bool enabled) async {}
}

/// Mirrors one session into the bridge, only sending what changed.
class SharedSync {
  SharedSync(this.bridge, this.session, this.identity, {required this.liveActivity}) {
    unawaited(bridge.setTv(session.tv, identity));
    session.addListener(_onChange);
    _onChange();
  }

  final SharedBridge bridge;
  final TvSession session;
  final ClientIdentity identity;
  final ValueListenable<bool> liveActivity;
  SharedStatusData? _status;
  List<String>? _apps;
  bool? _activity;

  void _onChange() {
    final v = session.volume;
    final status = SharedStatusData(
      connected: session.isConnected,
      appLabel: session.currentAppLabel,
      title: session.nowPlaying?.title,
      volume: v?.level,
      volumeMax: v?.max,
      muted: v?.muted ?? false,
    );
    if (status != _status) {
      _status = status;
      unawaited(bridge.updateStatus(status));
    }
    final apps = session.pinnedApps;
    final key = [for (final a in apps) '${a.package}|${a.label}'];
    if (!listEquals(key, _apps)) {
      _apps = key;
      unawaited(bridge.setApps(apps));
    }
    final wantActivity = liveActivity.value && session.isConnected;
    if (wantActivity != _activity) {
      _activity = wantActivity;
      unawaited(bridge.setLiveActivity(wantActivity));
    }
  }

  /// Re-evaluates after the Live Activity preference changed.
  void refresh() => _onChange();

  void dispose() {
    session.removeListener(_onChange);
    if (_activity == true) unawaited(bridge.setLiveActivity(false));
  }
}
