import 'dart:async';

import 'crypto/certificate.dart';
import 'errors.dart';
import 'keys.dart';
import 'pairing.dart';
import 'proto/remotemessage.pb.dart';
import 'remote.dart';
import 'state.dart';
import 'transport.dart';

/// Connection status as the app shows it.
enum AtvConnectionStatus {
  /// Not started, or stopped.
  idle,

  /// Opening the connection.
  connecting,

  /// Ready for commands.
  connected,

  /// The TV did not answer; retrying with backoff.
  unreachable,

  /// The TV no longer accepts this device: pairing is required.
  needsPairing,
}

/// Signature of [AtvRemote.connect], replaceable in tests.
typedef RemoteConnectFn = Future<AtvRemote> Function();

/// Keeps a connection to one TV alive: reconnects with exponential backoff
/// (100 ms doubling to [maxBackoff]) and stops when pairing is required.
class AtvClient {
  AtvClient({
    required this.host,
    required ClientIdentity identity,
    int port = defaultRemotePort,
    AtvConnector connector = const TlsConnector(),
    this.initialBackoff = const Duration(milliseconds: 100),
    this.maxBackoff = const Duration(seconds: 30),
    RemoteConnectFn? connect,
  }) : _connect = connect ??
            (() => AtvRemote.connect(host: host, port: port, identity: identity, connector: connector));

  final String host;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final RemoteConnectFn _connect;

  final _status = StreamController<AtvConnectionStatus>.broadcast(sync: true);
  final _states = StreamController<AtvState>.broadcast(sync: true);
  AtvConnectionStatus _current = AtvConnectionStatus.idle;
  AtvRemote? _remote;
  AtvState _state = const AtvState();
  bool _running = false;
  Completer<void>? _wake;
  AtvException? lastError;

  AtvConnectionStatus get status => _current;
  Stream<AtvConnectionStatus> get statusChanges => _status.stream;

  AtvState get state => _state;
  Stream<AtvState> get stateChanges => _states.stream;

  bool get isConnected => _current == AtvConnectionStatus.connected && _remote != null && !_remote!.isClosed;

  void _setStatus(AtvConnectionStatus s) {
    if (_current == s) return;
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  /// Starts the connect/reconnect loop. Safe to call again after [stop] or
  /// after pairing again.
  void start() {
    if (_running) return;
    _running = true;
    unawaited(_loop());
  }

  /// Skips the current backoff wait (e.g. when the app returns to foreground).
  void retryNow() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  Future<void> _loop() async {
    var backoff = initialBackoff;
    while (_running) {
      _setStatus(AtvConnectionStatus.connecting);
      try {
        final remote = await _connect();
        if (!_running) {
          await remote.close();
          break;
        }
        _remote = remote;
        lastError = null;
        backoff = initialBackoff;
        _publishState(remote.state);
        final sub = remote.stateChanges.listen(_publishState);
        _setStatus(AtvConnectionStatus.connected);
        final connectedAt = DateTime.now();
        lastError = await remote.done;
        await sub.cancel();
        _remote = null;
        if (!_running) break;
        _setStatus(AtvConnectionStatus.unreachable);
        // A connection that lived a while is retried at once; one that drops
        // immediately goes through the backoff so we never spin.
        if (DateTime.now().difference(connectedAt) > const Duration(seconds: 2)) continue;
      } on AtvAuthException catch (e) {
        lastError = e;
        _running = false;
        _setStatus(AtvConnectionStatus.needsPairing);
        return;
      } on AtvException catch (e) {
        lastError = e;
        _setStatus(AtvConnectionStatus.unreachable);
      }
      if (!_running) break;
      final wake = _wake = Completer<void>();
      await Future.any([Future<void>.delayed(backoff), wake.future]);
      _wake = null;
      final doubled = backoff * 2;
      backoff = doubled > maxBackoff ? maxBackoff : doubled;
    }
    if (_current != AtvConnectionStatus.needsPairing) _setStatus(AtvConnectionStatus.idle);
  }

  void _publishState(AtvState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  AtvRemote _requireRemote() {
    final r = _remote;
    if (r == null || r.isClosed) throw const AtvConnectionClosedException('not connected to the TV');
    return r;
  }

  void press(AtvKey key, {KeyDirection direction = KeyDirection.short}) =>
      _requireRemote().press(key, direction: direction);

  void sendKey(RemoteKeyCode key, {KeyDirection direction = KeyDirection.short}) =>
      _requireRemote().sendKey(key, direction: direction);

  void sendText(String text) => _requireRemote().sendText(text);

  void launchApp(String packageOrUrl) => _requireRemote().launchApp(packageOrUrl);

  /// Stops reconnecting and closes the connection.
  Future<void> stop() async {
    _running = false;
    retryNow();
    final r = _remote;
    _remote = null;
    if (r != null) await r.close();
    _setStatus(AtvConnectionStatus.idle);
  }

  /// Stops and releases the streams. The client cannot be restarted.
  Future<void> dispose() async {
    await stop();
    await _status.close();
    await _states.close();
  }
}
