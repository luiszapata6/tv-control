import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../errors.dart';
import 'der.dart';

const _oidRsaEncryption = '1.2.840.113549.1.1.1';
const _oidSha256WithRsa = '1.2.840.113549.1.1.11';
const _oidCommonName = '2.5.4.3';
const _oidBasicConstraints = '2.5.29.19';

/// RSA modulus and public exponent of a certificate.
class RsaPublicNumbers {
  const RsaPublicNumbers(this.modulus, this.exponent);
  final BigInt modulus;
  final BigInt exponent;

  @override
  bool operator ==(Object other) =>
      other is RsaPublicNumbers && other.modulus == modulus && other.exponent == exponent;

  @override
  int get hashCode => Object.hash(modulus, exponent);
}

/// The fields of an X.509 certificate this package needs.
class CertificateInfo {
  CertificateInfo._(this.publicNumbers, this.subjectCommonName, this.tbsDer, this.signature);

  final RsaPublicNumbers publicNumbers;
  final String? subjectCommonName;
  final Uint8List tbsDer;
  final Uint8List signature;

  /// Parses a DER certificate whose key is RSA (Android TVs always use RSA).
  factory CertificateInfo.parse(List<int> der) {
    try {
      final cert = DerReader(der).read();
      final parts = cert.children;
      final tbs = parts[0];
      final fields = tbs.children;
      var i = 0;
      if (fields[i].tag == DerTag.context(0)) i++; // explicit version
      i++; // serialNumber
      i++; // signature algorithm
      i++; // issuer
      i++; // validity
      final subject = fields[i++];
      final spki = fields[i++].children;
      final algorithm = spki[0].children[0].asOid;
      if (algorithm != _oidRsaEncryption) {
        throw AtvProtocolException('certificate key is not RSA ($algorithm)');
      }
      final rsa = DerReader(spki[1].bitStringBytes).read().children;
      return CertificateInfo._(
        RsaPublicNumbers(rsa[0].asBigInt, rsa[1].asBigInt),
        _commonName(subject),
        tbs.encoded,
        parts[2].bitStringBytes,
      );
    } on AtvProtocolException {
      rethrow;
    } catch (e) {
      throw AtvProtocolException('could not parse certificate', e);
    }
  }

  static String? _commonName(DerNode name) {
    for (final rdn in name.children) {
      for (final atv in rdn.children) {
        final pair = atv.children;
        if (pair.length == 2 && pair[0].asOid == _oidCommonName) return pair[1].asString;
      }
    }
    return null;
  }

  /// Verifies a self-signed SHA-256/RSA signature with this certificate's own key.
  bool verifySelfSignature() {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(false, PublicKeyParameter<RSAPublicKey>(RSAPublicKey(publicNumbers.modulus, publicNumbers.exponent)));
    try {
      return signer.verifySignature(tbsDer, RSASignature(signature));
    } catch (_) {
      return false;
    }
  }
}

/// The client certificate + private key a TV remembers after pairing. Keep it
/// secret and stable: losing it means pairing again.
class ClientIdentity {
  ClientIdentity({required this.certificatePem, required this.privateKeyPem})
      : certificateDer = pemToDer(certificatePem, 'CERTIFICATE');

  final String certificatePem;
  final String privateKeyPem;
  final Uint8List certificateDer;

  late final CertificateInfo info = CertificateInfo.parse(certificateDer);

  RsaPublicNumbers get publicNumbers => info.publicNumbers;

  Map<String, String> toJson() => {'certificate': certificatePem, 'privateKey': privateKeyPem};

  factory ClientIdentity.fromJson(Map<String, dynamic> json) => ClientIdentity(
        certificatePem: json['certificate'] as String,
        privateKeyPem: json['privateKey'] as String,
      );

  /// Generates a new RSA key and self-signed certificate. 2048-bit key
  /// generation takes a few seconds, so by default it runs in a background
  /// isolate; pass [inIsolate] false in tests or isolates.
  static Future<ClientIdentity> generate({
    String commonName = 'atvremote',
    int bits = 2048,
    bool inIsolate = true,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now().toUtc();
    if (!inIsolate) return _generate(commonName, bits, when);
    final json = await Isolate.run(() => _generate(commonName, bits, when).toJson());
    return ClientIdentity.fromJson(json);
  }

  static ClientIdentity _generate(String commonName, int bits, DateTime now) {
    final random = _secureRandom();
    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.from(65537), bits, 64), random));
    final pair = generator.generateKeyPair();
    final public = pair.publicKey as RSAPublicKey;
    final private = pair.privateKey as RSAPrivateKey;

    final name = Der.sequence([
      Der.set([
        Der.sequence([Der.oid(_oidCommonName), Der.utf8String(commonName)]),
      ]),
    ]);
    final algorithm = Der.sequence([Der.oid(_oidSha256WithRsa), Der.nullValue()]);
    final spki = Der.sequence([
      Der.sequence([Der.oid(_oidRsaEncryption), Der.nullValue()]),
      Der.bitString(Der.sequence([Der.integer(public.modulus!), Der.integer(public.publicExponent!)])),
    ]);
    final serial = BigInt.parse(
      List.generate(16, (_) => random.nextUint8().toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
    final extensions = Der.context(3, Der.sequence([
      Der.sequence([
        Der.oid(_oidBasicConstraints),
        Der.tlv(DerTag.octetString, Der.sequence([])), // cA = FALSE (default)
      ]),
    ]));
    final tbs = Der.sequence([
      Der.context(0, Der.smallInt(2)), // v3
      Der.integer(serial | BigInt.one),
      algorithm,
      name,
      Der.sequence([Der.time(now.subtract(const Duration(days: 1))), Der.time(now.add(const Duration(days: 365 * 20)))]),
      name,
      spki,
      extensions,
    ]);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(private));
    final signature = signer.generateSignature(tbs).bytes;
    final cert = Der.sequence([tbs, algorithm, Der.bitString(signature)]);

    final p = private.p!, q = private.q!, d = private.privateExponent!;
    final pkcs1 = Der.sequence([
      Der.smallInt(0),
      Der.integer(private.modulus!),
      Der.integer(public.publicExponent!),
      Der.integer(d),
      Der.integer(p),
      Der.integer(q),
      Der.integer(d % (p - BigInt.one)),
      Der.integer(d % (q - BigInt.one)),
      Der.integer(q.modInverse(p)),
    ]);
    return ClientIdentity(
      certificatePem: derToPem(cert, 'CERTIFICATE'),
      privateKeyPem: derToPem(pkcs1, 'RSA PRIVATE KEY'),
    );
  }

  static SecureRandom _secureRandom() {
    final seed = Random.secure();
    return FortunaRandom()..seed(KeyParameter(Uint8List.fromList(List.generate(32, (_) => seed.nextInt(256)))));
  }
}

/// Wraps [der] in a PEM block with 64-column base64 lines.
String derToPem(List<int> der, String label) {
  final b64 = base64.encode(der);
  final lines = [for (var i = 0; i < b64.length; i += 64) b64.substring(i, i + 64 > b64.length ? b64.length : i + 64)];
  return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
}

/// Extracts the DER bytes of the first PEM block labelled [label].
Uint8List pemToDer(String pem, String label) {
  final begin = '-----BEGIN $label-----';
  final end = '-----END $label-----';
  final start = pem.indexOf(begin);
  final stop = pem.indexOf(end, start + 1);
  if (start < 0 || stop < 0) throw AtvProtocolException('no $label PEM block');
  final body = pem.substring(start + begin.length, stop).replaceAll(RegExp(r'\s'), '');
  return base64.decode(body);
}
