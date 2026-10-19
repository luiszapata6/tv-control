import 'dart:convert';
import 'dart:io';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/src/crypto/der.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

void main() {
  final vectors = (golden['pairing'] as List).cast<Map<String, dynamic>>();
  final v = vectors.first;

  group('parsing certificates made by the reference (cryptography)', () {
    test('server certificate: RSA numbers, subject, signature', () {
      final info = CertificateInfo.parse(hexBytes(v['server_cert_der'] as String));
      expect(info.publicNumbers.modulus, BigInt.parse(v['server_modulus_hex'] as String, radix: 16));
      expect(info.publicNumbers.exponent, BigInt.from(v['server_exponent'] as int));
      expect(info.subjectCommonName, 'atvremote/65U6GA/65U6GA/Hisense 65U6GA/AA:BB:CC:DD:EE:FF');
      expect(info.verifySelfSignature(), isTrue);
    });

    test('client certificate from PEM', () {
      final der = pemToDer(v['client_cert_pem'] as String, 'CERTIFICATE');
      final info = CertificateInfo.parse(der);
      expect(info.publicNumbers.modulus, BigInt.parse(v['client_modulus_hex'] as String, radix: 16));
      expect(info.publicNumbers.exponent, BigInt.from(65537));
    });

    test('garbage is rejected with AtvProtocolException', () {
      expect(() => CertificateInfo.parse([0x30, 0x03, 0x02, 0x01, 0x01]), throwsA(isA<AtvProtocolException>()));
      expect(() => CertificateInfo.parse([1, 2, 3]), throwsA(isA<AtvProtocolException>()));
    });
  });

  group('TV subject', () {
    test('SHIELD style common name', () {
      final s = parseTvSubject('atvremote/darcy/darcy/SHIELD Android TV/aa:bb:cc:dd:ee:ff');
      expect(s.name, 'SHIELD Android TV');
      expect(s.mac, 'AA:BB:CC:DD:EE:FF');
    });
    test('Nexus Player style uses dnQualifier', () {
      final s = parseTvSubject('atvremote/11:22:33:44:55:66', dnQualifier: 'fugu/fugu/Nexus Player');
      expect(s.name, 'Nexus Player');
      expect(s.mac, '11:22:33:44:55:66');
    });
    test('no separators', () {
      final s = parseTvSubject('My TV');
      expect(s.name, 'My TV');
      expect(s.mac, isNull);
    });
  });

  group('generated identity', () {
    late ClientIdentity id;
    setUpAll(() async => id = await ClientIdentity.generate(commonName: 'TV Control', bits: 2048, inIsolate: true));

    test('is a valid self-signed RSA 2048 certificate', () {
      expect(id.info.subjectCommonName, 'TV Control');
      expect(id.publicNumbers.exponent, BigInt.from(65537));
      expect(id.publicNumbers.modulus.bitLength, 2048);
      expect(id.info.verifySelfSignature(), isTrue);
    });

    test('private key PEM is PKCS#1 and matches the certificate modulus', () {
      expect(id.privateKeyPem, startsWith('-----BEGIN RSA PRIVATE KEY-----'));
      final fields = DerReader(pemToDer(id.privateKeyPem, 'RSA PRIVATE KEY')).read().children;
      expect(fields, hasLength(9));
      expect(fields[1].asBigInt, id.publicNumbers.modulus);
      final n = fields[1].asBigInt, p = fields[4].asBigInt, q = fields[5].asBigInt;
      expect(p * q, n);
    });

    test('JSON round trip', () {
      final copy = ClientIdentity.fromJson(id.toJson());
      expect(copy.publicNumbers, id.publicNumbers);
      expect(copy.certificatePem, id.certificatePem);
    });

    test('dart:io accepts it for TLS', () {
      // Throws if BoringSSL cannot load the certificate or the key.
      expect(
        () => SecurityContext(withTrustedRoots: false)
          ..useCertificateChainBytes(utf8.encode(id.certificatePem))
          ..usePrivateKeyBytes(utf8.encode(id.privateKeyPem)),
        returnsNormally,
      );
    });
  });

  group('DER', () {
    test('INTEGER pads positive values with a high bit', () {
      expect(toHex(Der.integer(BigInt.from(128))), '02020080');
      expect(toHex(Der.integer(BigInt.zero)), '020100');
    });
    test('OID encoding', () {
      expect(toHex(Der.oid('1.2.840.113549.1.1.11')), '06092a864886f70d01010b');
      expect(DerReader(Der.oid('2.5.4.3')).read().asOid, '2.5.4.3');
    });
    test('long lengths', () {
      final big = Der.tlv(0x04, List.filled(300, 1));
      expect(big.sublist(0, 4), [0x04, 0x82, 0x01, 0x2c]);
      expect(DerReader(big).read().value.length, 300);
    });
    test('times switch to GeneralizedTime from 2050', () {
      expect(Der.time(DateTime.utc(2049, 12, 31))[0], DerTag.utcTime);
      expect(Der.time(DateTime.utc(2050, 1, 1))[0], DerTag.generalizedTime);
    });
  });
}
