import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'crypto/certificate.dart';
import 'errors.dart';

/// A connected, framed-message-agnostic byte channel to the TV.
abstract class AtvSocket {
  /// Bytes from the TV. Completes when the connection closes; errors are
  /// delivered as [AtvException]s.
  Stream<Uint8List> get input;

  /// Sends bytes to the TV. Ignored after [close].
  void add(List<int> bytes);

  /// DER of the TV's certificate (needed for the pairing secret).
  Uint8List? get peerCertificateDer;

  Future<void> close();
}

/// Opens [AtvSocket]s. Swapped for an in-memory fake in tests.
abstract class AtvConnector {
  Future<AtvSocket> connect(
    String host,
    int port,
    ClientIdentity identity, {
    Duration timeout = const Duration(seconds: 6),
  });
}

/// Whether a TLS error is the peer refusing our certificate (a TLS alert such
/// as bad_certificate / unknown_ca / certificate_required) rather than the
/// connection simply dropping.
bool isCertificateRejection(TlsException e) {
  final text = '${e.message} ${e.osError?.message ?? ''}'.toUpperCase();
  return text.contains('ALERT') || text.contains('CERTIFICATE');
}

/// TLS connector: presents our certificate and accepts the TV's self-signed one
/// (the TV is identified by pairing, not by a CA).
class TlsConnector implements AtvConnector {
  const TlsConnector();

  @override
  Future<AtvSocket> connect(
    String host,
    int port,
    ClientIdentity identity, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final SecurityContext context;
    try {
      context = SecurityContext(withTrustedRoots: false)
        ..useCertificateChainBytes(utf8.encode(identity.certificatePem))
        ..usePrivateKeyBytes(utf8.encode(identity.privateKeyPem));
    } on TlsException catch (e) {
      throw AtvAuthException('the stored device certificate is invalid; pair again', e);
    }
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        context: context,
        onBadCertificate: (_) => true,
        timeout: timeout,
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      return _TlsSocket(socket);
    } on TlsException catch (e) {
      // HandshakeException is a TlsException.
      if (isCertificateRejection(e)) throw AtvAuthException('the TV rejected this device; pair again', e);
      throw AtvHandshakeException('the secure connection to $host:$port broke off', e);
    } on SocketException catch (e) {
      throw AtvConnectionException('could not reach $host:$port', e);
    } on TimeoutException catch (e) {
      throw AtvConnectionException('timed out connecting to $host:$port', e);
    }
  }
}

class _TlsSocket implements AtvSocket {
  _TlsSocket(this._socket) {
    _input = _socket.handleError((Object e, StackTrace st) {
      // With TLS 1.3 the server checks our certificate after the handshake,
      // so a rejection shows up as the first read error.
      if (e is TlsException && isCertificateRejection(e)) {
        throw AtvAuthException('the TV rejected this device; pair again', e);
      }
      if (e is TlsException) throw AtvHandshakeException('the secure connection broke off', e);
      throw AtvConnectionClosedException('connection error', e);
    }).asBroadcastStream();
  }

  final SecureSocket _socket;
  late final Stream<Uint8List> _input;
  bool _closed = false;

  @override
  Stream<Uint8List> get input => _input;

  @override
  Uint8List? get peerCertificateDer => _socket.peerCertificate?.der;

  @override
  void add(List<int> bytes) {
    if (_closed) return;
    try {
      _socket.add(bytes);
    } catch (_) {
      // The input stream reports the failure.
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _socket.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      _socket.destroy();
    }
  }
}

/// In-memory socket pair for tests and simulations.
class MemorySocketPair {
  MemorySocketPair({Uint8List? clientCertDer, Uint8List? serverCertDer}) {
    client = _MemorySocket(_toClient, _toServer, serverCertDer);
    server = _MemorySocket(_toServer, _toClient, clientCertDer);
  }

  final _toClient = StreamController<Uint8List>();
  final _toServer = StreamController<Uint8List>();
  late final AtvSocket client;
  late final AtvSocket server;
}

class _MemorySocket implements AtvSocket {
  _MemorySocket(this._in, this._out, this.peerCertificateDer);
  final StreamController<Uint8List> _in;
  final StreamController<Uint8List> _out;

  @override
  final Uint8List? peerCertificateDer;

  @override
  Stream<Uint8List> get input => _in.stream;

  @override
  void add(List<int> bytes) {
    if (!_out.isClosed) _out.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> close() async {
    // Not awaited: a controller's done future only completes once listened to.
    if (!_out.isClosed) unawaited(_out.close());
    if (!_in.isClosed) unawaited(_in.close());
  }
}
