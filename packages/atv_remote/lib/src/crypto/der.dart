import 'dart:convert';
import 'dart:typed_data';

import '../errors.dart';

/// DER tags used by X.509.
abstract final class DerTag {
  static const integer = 0x02;
  static const bitString = 0x03;
  static const octetString = 0x04;
  static const nullTag = 0x05;
  static const oid = 0x06;
  static const utf8String = 0x0c;
  static const printableString = 0x13;
  static const utcTime = 0x17;
  static const generalizedTime = 0x18;
  static const sequence = 0x30;
  static const set = 0x31;

  /// Explicit context-specific constructed tag `[n]`.
  static int context(int n) => 0xa0 | n;
}

/// Minimal DER encoder.
abstract final class Der {
  static Uint8List tlv(int tag, List<int> value) {
    final out = BytesBuilder(copy: false)..addByte(tag);
    _length(value.length, out);
    out.add(value);
    return out.takeBytes();
  }

  static void _length(int length, BytesBuilder out) {
    if (length < 0x80) {
      out.addByte(length);
      return;
    }
    final bytes = <int>[];
    var l = length;
    while (l > 0) {
      bytes.insert(0, l & 0xff);
      l >>= 8;
    }
    out.addByte(0x80 | bytes.length);
    out.add(bytes);
  }

  static Uint8List sequence(Iterable<List<int>> items) => tlv(DerTag.sequence, items.expand((e) => e).toList());

  static Uint8List set(Iterable<List<int>> items) => tlv(DerTag.set, items.expand((e) => e).toList());

  static Uint8List context(int n, List<int> inner) => tlv(DerTag.context(n), inner);

  /// INTEGER: minimal two's complement (a 0x00 pad keeps positives positive).
  static Uint8List integer(BigInt value) {
    if (value.isNegative) throw ArgumentError('negative integers are not needed here');
    var bytes = bigIntToBytes(value);
    if (bytes.isEmpty) bytes = Uint8List.fromList([0]);
    if (bytes[0] & 0x80 != 0) bytes = Uint8List.fromList([0, ...bytes]);
    return tlv(DerTag.integer, bytes);
  }

  static Uint8List smallInt(int value) => integer(BigInt.from(value));

  static Uint8List nullValue() => tlv(DerTag.nullTag, const []);

  static Uint8List oid(String dotted) {
    final parts = dotted.split('.').map(int.parse).toList();
    final out = <int>[parts[0] * 40 + parts[1]];
    for (final p in parts.skip(2)) {
      final chunk = <int>[p & 0x7f];
      var v = p >> 7;
      while (v > 0) {
        chunk.insert(0, (v & 0x7f) | 0x80);
        v >>= 7;
      }
      out.addAll(chunk);
    }
    return tlv(DerTag.oid, out);
  }

  static Uint8List bitString(List<int> bytes) => tlv(DerTag.bitString, [0, ...bytes]);

  static Uint8List utf8String(String s) => tlv(DerTag.utf8String, utf8.encode(s));

  /// UTCTime before 2050, GeneralizedTime after (RFC 5280 4.1.2.5).
  static Uint8List time(DateTime t) {
    final u = t.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final rest = '${two(u.month)}${two(u.day)}${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    if (u.year < 2050) {
      return tlv(DerTag.utcTime, ascii.encode('${two(u.year % 100)}$rest'));
    }
    return tlv(DerTag.generalizedTime, ascii.encode('${u.year.toString().padLeft(4, '0')}$rest'));
  }
}

/// One decoded DER element.
class DerNode {
  DerNode(this.tag, this.value, this.encoded);
  final int tag;
  final Uint8List value;

  /// The full TLV bytes (needed to re-hash the TBSCertificate).
  final Uint8List encoded;

  bool get isConstructed => tag & 0x20 != 0;

  List<DerNode> get children => DerReader(value).readAll();

  BigInt get asBigInt {
    if (tag != DerTag.integer) throw const AtvProtocolException('expected INTEGER');
    return bytesToBigInt(value);
  }

  String get asOid {
    if (tag != DerTag.oid || value.isEmpty) throw const AtvProtocolException('expected OID');
    final parts = <int>[value[0] ~/ 40, value[0] % 40];
    var acc = 0;
    for (final b in value.skip(1)) {
      acc = (acc << 7) | (b & 0x7f);
      if (b & 0x80 == 0) {
        parts.add(acc);
        acc = 0;
      }
    }
    return parts.join('.');
  }

  String get asString => utf8.decode(value, allowMalformed: true);

  /// BIT STRING contents without the unused-bits byte.
  Uint8List get bitStringBytes {
    if (tag != DerTag.bitString || value.isEmpty) throw const AtvProtocolException('expected BIT STRING');
    return Uint8List.sublistView(value, 1);
  }
}

/// Sequential DER decoder.
class DerReader {
  DerReader(List<int> bytes) : _bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final Uint8List _bytes;
  int _pos = 0;

  bool get isAtEnd => _pos >= _bytes.length;

  DerNode read() {
    final start = _pos;
    if (_pos + 2 > _bytes.length) throw const AtvProtocolException('truncated DER');
    final tag = _bytes[_pos++];
    var length = _bytes[_pos++];
    if (length & 0x80 != 0) {
      final n = length & 0x7f;
      if (n == 0 || n > 4 || _pos + n > _bytes.length) throw const AtvProtocolException('bad DER length');
      length = 0;
      for (var i = 0; i < n; i++) {
        length = (length << 8) | _bytes[_pos++];
      }
    }
    if (_pos + length > _bytes.length) throw const AtvProtocolException('DER value past end');
    final value = Uint8List.sublistView(_bytes, _pos, _pos + length);
    _pos += length;
    return DerNode(tag, value, Uint8List.sublistView(_bytes, start, _pos));
  }

  List<DerNode> readAll() {
    final out = <DerNode>[];
    while (!isAtEnd) {
      out.add(read());
    }
    return out;
  }
}

/// Unsigned big-endian bytes of [value] without leading zeros (empty for 0).
Uint8List bigIntToBytes(BigInt value) {
  if (value.isNegative) throw ArgumentError('negative');
  if (value == BigInt.zero) return Uint8List(0);
  final hex = value.toRadixString(16);
  final padded = hex.length.isOdd ? '0$hex' : hex;
  final out = Uint8List(padded.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(padded.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Interprets [bytes] as an unsigned big-endian integer (a DER INTEGER that is
/// positive, i.e. with any 0x00 sign pad, decodes the same).
BigInt bytesToBigInt(List<int> bytes) {
  var result = BigInt.zero;
  for (final b in bytes) {
    result = (result << 8) | BigInt.from(b);
  }
  return result;
}
