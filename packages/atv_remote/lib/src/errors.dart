/// Base class of everything this package throws on purpose.
sealed class AtvException implements Exception {
  const AtvException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

/// The TV could not be reached (wrong IP, TV off, network down, timeout).
class AtvConnectionException extends AtvException {
  const AtvConnectionException(super.message, [super.cause]);
}

/// The TV refused our certificate: we must (re)pair before connecting.
class AtvAuthException extends AtvException {
  const AtvAuthException(super.message, [super.cause]);
}

/// Pairing failed: wrong code, cancelled on the TV, or protocol error.
class AtvPairingException extends AtvException {
  const AtvPairingException(super.message, [super.cause]);
}

/// The connection dropped while waiting for an answer or after being idle.
class AtvConnectionClosedException extends AtvException {
  const AtvConnectionClosedException(super.message, [super.cause]);
}

/// The peer sent bytes that do not follow the protocol.
class AtvProtocolException extends AtvException {
  const AtvProtocolException(super.message, [super.cause]);
}
