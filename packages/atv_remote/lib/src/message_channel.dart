import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'errors.dart';
import 'framing.dart';
import 'transport.dart';

/// Reads framed messages from an [AtvSocket] and writes framed messages to it.
///
/// Incoming messages can be consumed with [next] (request/response flows such
/// as pairing) or with [messages] (event-driven flows such as the remote).
class MessageChannel {
  MessageChannel(this.socket) {
    _sub = socket.input.listen(
      _onData,
      onError: _onError,
      onDone: () => _finish(const AtvConnectionClosedException('the TV closed the connection')),
      cancelOnError: true,
    );
  }

  final AtvSocket socket;
  final _deframer = MessageDeframer();
  final _queue = Queue<Uint8List>();
  final _waiters = Queue<Completer<Uint8List>>();
  final _closed = Completer<AtvException>();
  StreamController<Uint8List>? _stream;
  late final StreamSubscription<Uint8List> _sub;
  AtvException? _error;

  /// Completes with the reason once the connection is gone.
  Future<AtvException> get closed => _closed.future;

  bool get isClosed => _closed.isCompleted;

  /// All incoming messages as a stream. Once listened to, [next] stops
  /// receiving messages. Must be called at most once.
  Stream<Uint8List> get messages {
    final controller = _stream ??= StreamController<Uint8List>(sync: true);
    while (_queue.isNotEmpty) {
      controller.add(_queue.removeFirst());
    }
    if (_error != null && !controller.isClosed) controller.close();
    return controller.stream;
  }

  void send(List<int> payload) {
    if (isClosed) throw _error ?? const AtvConnectionClosedException('connection closed');
    socket.add(frameMessage(payload));
  }

  /// Waits for the next message, failing on close or after [timeout].
  Future<Uint8List> next({Duration timeout = const Duration(seconds: 10)}) {
    if (_queue.isNotEmpty) return Future.value(_queue.removeFirst());
    if (_error != null) return Future.error(_error!);
    final c = Completer<Uint8List>();
    _waiters.add(c);
    return c.future.timeout(timeout, onTimeout: () {
      _waiters.remove(c);
      throw const AtvConnectionClosedException('no answer from the TV in time');
    });
  }

  void _onData(Uint8List chunk) {
    List<Uint8List> messages;
    try {
      messages = _deframer.add(chunk);
    } on AtvException catch (e) {
      _finish(e);
      unawaited(socket.close());
      return;
    }
    for (final m in messages) {
      final stream = _stream;
      if (stream != null) {
        stream.add(m);
      } else if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete(m);
      } else {
        _queue.add(m);
      }
    }
  }

  void _onError(Object error, StackTrace st) {
    _finish(error is AtvException ? error : AtvConnectionClosedException('connection error', error));
  }

  void _finish(AtvException reason) {
    if (_closed.isCompleted) return;
    _error = reason;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().completeError(reason);
    }
    _stream?.close();
    _closed.complete(reason);
  }

  Future<void> close([AtvException? reason]) async {
    _finish(reason ?? const AtvConnectionClosedException('closed by the app'));
    await _sub.cancel();
    await socket.close();
  }
}
