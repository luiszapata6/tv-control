import 'package:atv_remote/atv_remote.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

void main() {
  final vectors = (golden['pairing'] as List).cast<Map<String, dynamic>>();

  RsaPublicNumbers numbers(Map<String, dynamic> v, String side) => RsaPublicNumbers(
        BigInt.parse(v['${side}_modulus_hex'] as String, radix: 16),
        BigInt.from(v['${side}_exponent'] as int),
      );

  for (final v in vectors) {
    test('secret for code ${v['code']} matches the reference', () {
      final secret = computePairingSecret(client: numbers(v, 'client'), server: numbers(v, 'server'), code: v['code'] as String);
      expect(toHex(secret), v['secret_hex']);
    });
  }

  test('lowercase, spaces and dashes are accepted', () {
    final v = vectors[1];
    final code = v['code'] as String;
    final messy = ' ${code.substring(0, 3).toLowerCase()}-${code.substring(3)} ';
    expect(
      toHex(computePairingSecret(client: numbers(v, 'client'), server: numbers(v, 'server'), code: messy)),
      v['secret_hex'],
    );
  });

  test('a typo is caught by the check byte', () {
    final v = vectors[1];
    final code = v['code'] as String;
    final typo = '${code.substring(0, 5)}${code[5] == '0' ? '1' : '0'}';
    expect(
      () => computePairingSecret(client: numbers(v, 'client'), server: numbers(v, 'server'), code: typo),
      throwsA(isA<AtvPairingException>()),
    );
  });

  test('format validation', () {
    expect(isValidPairingCode('1a2B3c'), isTrue);
    expect(isValidPairingCode('12 34 56'), isTrue);
    expect(isValidPairingCode('12345'), isFalse);
    expect(isValidPairingCode('12345G'), isFalse);
    expect(normalizePairingCode(' ab-cd ef'), 'ABCDEF');
  });
}
