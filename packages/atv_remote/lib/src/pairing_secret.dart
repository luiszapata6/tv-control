import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'crypto/certificate.dart';
import 'crypto/der.dart';
import 'errors.dart';

/// Normalizes what the user typed: trims, removes spaces and dashes, upper-cases.
String normalizePairingCode(String input) => input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

/// True if [code] looks like a TV pairing code (6 hexadecimal characters).
bool isValidPairingCode(String code) => RegExp(r'^[0-9A-F]{6}$').hasMatch(normalizePairingCode(code));

/// Computes the pairing secret for [code].
///
/// The TV shows 6 hex digits: the first two are the first byte of
/// SHA-256(client n, client e, server n, server e, nonce) and the last four are
/// the nonce. The check byte catches typos before anything is sent.
///
/// Throws [AtvPairingException] if the code is malformed or the check byte
/// does not match (usually a typo).
Uint8List computePairingSecret({
  required RsaPublicNumbers client,
  required RsaPublicNumbers server,
  required String code,
}) {
  final normalized = normalizePairingCode(code);
  if (!isValidPairingCode(normalized)) {
    throw const AtvPairingException('the code must be 6 characters (0-9, A-F)');
  }
  final nonce = Uint8List.fromList([
    int.parse(normalized.substring(2, 4), radix: 16),
    int.parse(normalized.substring(4, 6), radix: 16),
  ]);
  final digest = sha256.convert([
    ...bigIntToBytes(client.modulus),
    ...bigIntToBytes(client.exponent),
    ...bigIntToBytes(server.modulus),
    ...bigIntToBytes(server.exponent),
    ...nonce,
  ]).bytes;
  if (digest[0] != int.parse(normalized.substring(0, 2), radix: 16)) {
    throw const AtvPairingException('the code does not match; check it on the TV');
  }
  return Uint8List.fromList(digest);
}
