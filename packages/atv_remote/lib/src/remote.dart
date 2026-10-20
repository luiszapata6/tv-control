import 'dart:async';
import 'dart:typed_data';

import 'apps.dart';
import 'crypto/certificate.dart';
import 'errors.dart';
import 'keys.dart';
import 'message_channel.dart';
import 'pairing.dart';
import 'proto/remotemessage.pb.dart';
import 'state.dart';
import 'transport.dart';

/// A live command connection to a paired TV on the remote port (6466).
///
/// [connect] completes once the TV sent `remote_start`, i.e. it accepts
/// commands. State pushed by the TV (power, volume, foreground app) is
/// available in [state] and [stateChanges]. The connection closes itself if
/// the TV stays silent for [idleTimeout] (the TV pings every ~5 s).
class AtvRemote {
  AtvRemote._(this._channel, this._requestedFeatures, this.idleTimeout, this.clientPackage);

  final MessageChannel _channel;
  final int _requestedFeatures;
  final Duration idleTimeout;
  final String clientPackage;

  final _states = StreamController<AtvState>.broadcast(sync: true);
  final _started = Completer<void>();
  late final StreamSubscription<Uint8List> _sub;
  Timer? _idle;
  AtvState _state = const AtvState();
  int _imeCounter = 0;
  int _fieldCounter = 0;

  AtvState get state => _state;

  /// Every state change pushed by the TV.
  Stream<AtvState> get stateChanges => _states.stream;

  /// Completes with the reason when the connection ends (never with an error).
  Future<AtvException> get done => _channel.closed;

  bool get isClosed => _channel.isClosed;

  /// Connects and waits until the TV is ready for commands.
  ///
  /// Throws [AtvAuthException] when the TV does not know this identity (pair
  /// first), [AtvConnectionException] when it cannot be reached.
  static Future<AtvRemote> connect({
    required String host,
    required ClientIdentity identity,
    int port = defaultRemotePort,
    AtvConnector connector = const TlsConnector(),
    int features = AtvFeature.defaults,
    Duration timeout = const Duration(seconds: 8),
    Duration idleTimeout = const Duration(seconds: 16),
    String clientPackage = 'atvremote',
  }) async {
    final socket = await connector.connect(host, port, identity, timeout: timeout);
    final remote = AtvRemote._(MessageChannel(socket), features, idleTimeout, clientPackage);
    remote._listen();
    try {
      await Future.any([remote._started.future, remote.done.then((e) => throw e)]).timeout(timeout);
    } on TimeoutException {
      await remote.close();
      throw const AtvConnectionException('the TV did not finish the handshake in time');
    } on AtvException {
      // TLS rejections of an unknown certificate surface as AtvAuthException
      // (from the transport); a plain close is reported as is.
      await remote.close();
      rethrow;
    }
    return remote;
  }

  void _listen() {
    _resetIdle();
    _sub = _channel.messages.listen(_onMessage);
    unawaited(_channel.closed.then((_) {
      _idle?.cancel();
      _states.close();
    }));
  }

  void _resetIdle() {
    _idle?.cancel();
    if (idleTimeout > Duration.zero) {
      _idle = Timer(idleTimeout, () {
        unawaited(close(const AtvConnectionClosedException('the TV stopped answering')));
      });
    }
  }

  void _setState(AtvState next) {
    if (next == _state) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  // Only incoming traffic resets the idle watchdog: the TV pings every ~5 s,
  // so a half-open connection is detected even while we keep sending.
  void _send(RemoteMessage message) {
    _channel.send(message.writeToBuffer());
  }

  void _onMessage(Uint8List raw) {
    _resetIdle();
    final RemoteMessage msg;
    try {
      msg = RemoteMessage.fromBuffer(raw);
    } catch (_) {
      return; // Unknown or corrupt message: ignore, like the reference client.
    }

    final configure = msg.remoteConfigure;
    final setActive = msg.remoteSetActive;
    final imeKey = msg.remoteImeKeyInject;
    final batch = msg.remoteImeBatchEdit;
    final volume = msg.remoteSetVolumeLevel;
    final start = msg.remoteStart;
    final ping = msg.remotePingRequest;

    if (configure != null) {
      final info = configure.deviceInfo;
      final agreed = _requestedFeatures & (configure.code1 ?? 0);
      _setState(_state.copyWith(
        features: agreed,
        deviceInfo: AtvDeviceInfo(
          vendor: info?.vendor ?? '',
          model: info?.model ?? '',
          appVersion: info?.appVersion ?? '',
        ),
      ));
      _send(RemoteMessage(
        remoteConfigure: RemoteConfigure(
          code1: agreed,
          deviceInfo: RemoteDeviceInfo(unknown1: 1, unknown2: '1', packageName: clientPackage, appVersion: '1.0.0'),
        ),
      ));
    } else if (setActive != null) {
      _send(RemoteMessage(remoteSetActive: RemoteSetActive(active: _state.features)));
    } else if (imeKey != null) {
      final app = imeKey.appInfo?.appPackage;
      if (app != null && app.isNotEmpty) _setState(_state.copyWith(currentApp: app));
    } else if (batch != null) {
      _imeCounter = batch.imeCounter ?? _imeCounter;
      _fieldCounter = batch.fieldCounter ?? _fieldCounter;
    } else if (volume != null) {
      _setState(_state.copyWith(
        volume: AtvVolume(
          level: volume.volumeLevel ?? 0,
          max: volume.volumeMax ?? 0,
          muted: volume.volumeMuted ?? false,
        ),
      ));
    } else if (start != null) {
      _setState(_state.copyWith(isOn: start.started ?? false));
      if (!_started.isCompleted) _started.complete();
    } else if (ping != null) {
      _send(RemoteMessage(remotePingResponse: RemotePingResponse(val1: ping.val1 ?? 0)));
    }
    // remote_error, voice and unknown messages need no answer.
  }

  void _ensureOpen() {
    if (isClosed) throw const AtvConnectionClosedException('not connected to the TV');
  }

  /// Presses [key]. For a long press send [KeyDirection.startLong] then
  /// [KeyDirection.endLong].
  void sendKey(RemoteKeyCode key, {KeyDirection direction = KeyDirection.short}) {
    _ensureOpen();
    _send(RemoteMessage(remoteKeyInject: RemoteKeyInject(keyCode: key, direction: direction.proto)));
  }

  /// Convenience for [sendKey] with an [AtvKey].
  void press(AtvKey key, {KeyDirection direction = KeyDirection.short}) => sendKey(key.code, direction: direction);

  /// Replaces the content of the focused text field on the TV with [text].
  ///
  /// Works while the TV shows a text field (search boxes, logins).
  void sendText(String text) {
    _ensureOpen();
    if (text.isEmpty) throw ArgumentError.value(text, 'text', 'cannot be empty; use sendKey(KEYCODE_DEL)');
    // The TV counts code points, not UTF-16 units (emoji are 2 units).
    final cursor = text.runes.length - 1;
    _send(RemoteMessage(
      remoteImeBatchEdit: RemoteImeBatchEdit(
        imeCounter: _imeCounter,
        fieldCounter: _fieldCounter,
        editInfo: [
          RemoteEditInfo(insert: 1, textFieldStatus: RemoteImeObject(start: cursor, end: cursor, value: text)),
        ],
      ),
    ));
  }

  /// Opens an app by package name or deep link URL (see [appLinkFor]).
  void launchApp(String packageOrUrl) {
    _ensureOpen();
    _send(RemoteMessage(remoteAppLinkLaunchRequest: RemoteAppLinkLaunchRequest(appLink: appLinkFor(packageOrUrl))));
  }

  Future<void> close([AtvException? reason]) async {
    _idle?.cancel();
    if (!_started.isCompleted) _started.completeError(reason ?? const AtvConnectionClosedException('closed'));
    _started.future.ignore();
    await _channel.close(reason);
    await _sub.cancel();
  }
}
