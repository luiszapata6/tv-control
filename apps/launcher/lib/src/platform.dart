import 'dart:async';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/services.dart';

/// An installed app that can be opened from the launcher.
class LauncherApp {
  const LauncherApp({required this.package, required this.label, this.isSystem = false});
  final String package;
  final String label;
  final bool isSystem;

  factory LauncherApp.fromMap(Map<Object?, Object?> m) => LauncherApp(
        package: m['package']! as String,
        label: (m['label'] as String?) ?? m['package']! as String,
        isSystem: (m['isSystem'] as bool?) ?? false,
      );
}

/// Events the native side pushes to the UI.
sealed class LauncherEvent {
  const LauncherEvent();
}

class AppsChanged extends LauncherEvent {
  const AppsChanged();
}

class LayoutChanged extends LauncherEvent {
  const LayoutChanged(this.layout);
  final LauncherLayout layout;
}

/// The TV must show [code] because [client] asked to pair (null hides it).
class PairingCodeChanged extends LauncherEvent {
  const PairingCodeChanged(this.code, this.client);
  final String? code;
  final String? client;
}

class CompanionClientsChanged extends LauncherEvent {
  const CompanionClientsChanged(this.names);
  final List<String> names;
}

/// Native services of the launcher (Kotlin side). Faked in tests.
abstract class LauncherPlatform {
  Future<List<LauncherApp>> apps();
  Future<Uint8List?> icon(String package);
  Future<void> launch(String package);
  Future<LauncherLayout> layout();
  Future<LauncherLayout> setLayout(LauncherLayout layout);
  Future<List<TvInput>> inputs();
  Future<void> openInput(String id);
  Future<void> openSystemSettings();
  Future<void> openAppInfo(String package);
  Future<String> companionAddress();

  /// Forgets every paired iPhone and disconnects them.
  Future<void> revokeDevices();
  Stream<LauncherEvent> get events;
}

class MethodChannelLauncherPlatform implements LauncherPlatform {
  static const _method = MethodChannel('tvcontrol/launcher');
  static const _events = EventChannel('tvcontrol/events');

  @override
  Future<List<LauncherApp>> apps() async {
    final list = await _method.invokeListMethod<Map<Object?, Object?>>('apps') ?? const [];
    return [for (final m in list) LauncherApp.fromMap(m)];
  }

  @override
  Future<Uint8List?> icon(String package) => _method.invokeMethod<Uint8List>('icon', {'package': package});

  @override
  Future<void> launch(String package) => _method.invokeMethod<void>('launch', {'package': package});

  @override
  Future<LauncherLayout> layout() async =>
      LauncherLayout.fromJson(_json(await _method.invokeMapMethod<String, Object?>('layout')));

  @override
  Future<LauncherLayout> setLayout(LauncherLayout layout) async => LauncherLayout.fromJson(
        _json(await _method.invokeMapMethod<String, Object?>('setLayout', {'layout': layout.toJson()})),
      );

  @override
  Future<List<TvInput>> inputs() async {
    final list = await _method.invokeListMethod<Map<Object?, Object?>>('inputs') ?? const [];
    return [for (final m in list) TvInput.fromJson(_json(m.cast<String, Object?>()))];
  }

  @override
  Future<void> openInput(String id) => _method.invokeMethod<void>('openInput', {'id': id});

  @override
  Future<void> openSystemSettings() => _method.invokeMethod<void>('openSettings');

  @override
  Future<void> openAppInfo(String package) => _method.invokeMethod<void>('openAppInfo', {'package': package});

  @override
  Future<String> companionAddress() async => await _method.invokeMethod<String>('companionAddress') ?? '';

  @override
  Future<void> revokeDevices() => _method.invokeMethod<void>('revokeDevices');

  @override
  late final Stream<LauncherEvent> events = _events.receiveBroadcastStream().map((raw) {
    final m = (raw as Map<Object?, Object?>).cast<String, Object?>();
    switch (m['type']) {
      case 'appsChanged':
        return const AppsChanged();
      case 'layoutChanged':
        return LayoutChanged(LauncherLayout.fromJson(_json(m['layout'] as Map<Object?, Object?>?)));
      case 'pairingCode':
        return PairingCodeChanged(m['code'] as String?, m['client'] as String?);
      case 'clients':
        return CompanionClientsChanged(((m['names'] as List<Object?>?) ?? const []).cast<String>());
      default:
        return const AppsChanged();
    }
  });

  static Map<String, dynamic> _json(Map<Object?, Object?>? m) {
    // Platform channels deliver nested maps/lists with Object? types.
    Object? convert(Object? v) => switch (v) {
          Map<Object?, Object?>() => {for (final e in v.entries) e.key as String: convert(e.value)},
          List<Object?>() => [for (final x in v) convert(x)],
          _ => v,
        };
    return (convert(m ?? const {}) as Map).cast<String, dynamic>();
  }
}
