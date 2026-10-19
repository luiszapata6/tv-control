import 'dart:async';
import 'dart:typed_data';

import 'crypto/certificate.dart';
import 'errors.dart';
import 'message_channel.dart';
import 'pairing_secret.dart';
import 'proto/polo.pb.dart';
import 'transport.dart';
import 'tv_subject.dart';

/// Default ports of the Android TV Remote service.
const int defaultPairingPort = 6467;
const int defaultRemotePort = 6466;

/// One pairing attempt. [start] makes the TV show a 6 character code; pass it
/// to [finish]. Afterwards the TV accepts [ClientIdentity] on the remote port.
class PairingSession {
  PairingSession._(this._channel, this.serverInfo, this.serverName, this._identity);

  final MessageChannel _channel;
  final ClientIdentity _identity;

  /// The TV's certificate (its key is part of the pairing secret).
  final CertificateInfo serverInfo;

  /// The name the TV reported in pairing_request_ack, if any.
  final String? serverName;

  /// Name and MAC (for Wake-on-LAN) from the TV certificate.
  TvSubject? get subject {
    final cn = serverInfo.subjectCommonName;
    return cn == null ? null : parseTvSubject(cn);
  }

  /// Connects and runs the handshake up to the point where the TV shows the code.
  static Future<PairingSession> start({
    required String host,
    required ClientIdentity identity,
    int port = defaultPairingPort,
    String clientName = 'TV Control',
    AtvConnector connector = const TlsConnector(),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await connector.connect(host, port, identity, timeout: timeout);
    final channel = MessageChannel(socket);
    try {
      final der = socket.peerCertificateDer;
      if (der == null) throw const AtvPairingException('the TV did not present a certificate');
      final serverInfo = CertificateInfo.parse(der);

      _send(channel, OuterMessage(pairingRequest: PairingRequest(serviceName: 'atvremote', clientName: clientName)));
      final ack = await _expect(channel, timeout, (m) => m.pairingRequestAck != null, 'pairing_request_ack');

      _send(
        channel,
        OuterMessage(
          options: Options(
            inputEncodings: [_hex6()],
            preferredRole: Options_RoleType.ROLE_TYPE_INPUT,
          ),
        ),
      );
      await _expect(channel, timeout, (m) => m.options != null, 'options');

      _send(
        channel,
        OuterMessage(configuration: Configuration(encoding: _hex6(), clientRole: Options_RoleType.ROLE_TYPE_INPUT)),
      );
      await _expect(channel, timeout, (m) => m.configurationAck != null, 'configuration_ack');
      return PairingSession._(channel, serverInfo, ack.pairingRequestAck?.serverName, identity);
    } catch (e) {
      await channel.close();
      if (e is AtvException) rethrow;
      throw AtvPairingException('pairing failed', e);
    }
  }

  /// Sends the secret derived from [code]. Completes when the TV accepts it.
  ///
  /// Throws [AtvPairingException] for a mistyped or wrong code (the session
  /// is closed; start again) or if the user cancelled on the TV.
  Future<void> finish(String code, {Duration timeout = const Duration(seconds: 10)}) async {
    final Uint8List secret;
    try {
      secret = computePairingSecret(
        client: _identity.publicNumbers,
        server: serverInfo.publicNumbers,
        code: code,
      );
    } on AtvPairingException {
      // A typo: keep the session open so the user can try again.
      rethrow;
    }
    try {
      _send(_channel, OuterMessage(secret: Secret(secret: secret)));
      await _expect(_channel, timeout, (m) => m.secretAck != null, 'secret_ack');
    } on AtvException catch (e) {
      if (e is AtvPairingException) rethrow;
      throw AtvPairingException('the TV did not accept the code', e);
    } finally {
      await _channel.close();
    }
  }

  /// Abandons pairing; the TV hides the code.
  Future<void> cancel() => _channel.close();

  static Options_Encoding _hex6() =>
      Options_Encoding(type: Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL, symbolLength: 6);

  static void _send(MessageChannel channel, OuterMessage message) {
    message
      ..protocolVersion = 2
      ..status = OuterMessage_Status.STATUS_OK;
    channel.send(message.writeToBuffer());
  }

  static Future<OuterMessage> _expect(
    MessageChannel channel,
    Duration timeout,
    bool Function(OuterMessage) matches,
    String what,
  ) async {
    final raw = await channel.next(timeout: timeout);
    final OuterMessage message;
    try {
      message = OuterMessage.fromBuffer(raw);
    } catch (e) {
      throw AtvProtocolException('invalid pairing message', e);
    }
    final status = message.status ?? OuterMessage_Status.STATUS_OK;
    if (status == OuterMessage_Status.STATUS_BAD_SECRET) {
      throw const AtvPairingException('wrong code');
    }
    if (status != OuterMessage_Status.STATUS_OK) {
      throw AtvPairingException('the TV answered ${status.name}');
    }
    if (!matches(message)) throw AtvProtocolException('expected $what, got $message');
    return message;
  }
}

/// Reads the TV's name and MAC address from its certificate without pairing.
Future<({CertificateInfo certificate, TvSubject? subject})> fetchTvCertificate({
  required String host,
  required ClientIdentity identity,
  int port = defaultPairingPort,
  AtvConnector connector = const TlsConnector(),
  Duration timeout = const Duration(seconds: 6),
}) async {
  final socket = await connector.connect(host, port, identity, timeout: timeout);
  try {
    final der = socket.peerCertificateDer;
    if (der == null) throw const AtvProtocolException('the TV did not present a certificate');
    final info = CertificateInfo.parse(der);
    final cn = info.subjectCommonName;
    return (certificate: info, subject: cn == null ? null : parseTvSubject(cn));
  } finally {
    await socket.close();
  }
}
