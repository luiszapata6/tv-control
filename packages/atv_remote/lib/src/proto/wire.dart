import 'dart:convert';
import 'dart:typed_data';

/// Protobuf wire types.
abstract final class WireType {
  static const varint = 0;
  static const fixed64 = 1;
  static const lengthDelimited = 2;
  static const startGroup = 3;
  static const endGroup = 4;
  static const fixed32 = 5;
}

/// Thrown when bytes cannot be decoded as protobuf.
class ProtoDecodeException implements Exception {
  ProtoDecodeException(this.message);
  final String message;
  @override
  String toString() => 'ProtoDecodeException: $message';
}

/// A field tag: number + wire type.
class ProtoTag {
  const ProtoTag(this.field, this.wireType);
  final int field;
  final int wireType;
}

/// Minimal protobuf encoder covering the scalar types used by the
/// Android TV Remote v2 schema.
class ProtoWriter {
  final BytesBuilder _out = BytesBuilder(copy: false);

  /// Appends [value] as a base-128 varint. Negative numbers are encoded as
  /// 64-bit two's complement (10 bytes), as protobuf does for int32.
  static void encodeVarint(int value, void Function(int byte) add) {
    var v = value;
    if (v < 0) {
      // Emit the 64-bit two's complement representation, 7 bits at a time.
      for (var i = 0; i < 9; i++) {
        add((v & 0x7f) | 0x80);
        v = v >> 7; // arithmetic shift keeps the sign bits
      }
      add(1);
      return;
    }
    while (v >= 0x80) {
      add((v & 0x7f) | 0x80);
      v = v >> 7;
    }
    add(v);
  }

  void _varint(int value) => encodeVarint(value, _out.addByte);

  void _tag(int field, int wireType) => _varint((field << 3) | wireType);

  void writeInt32(int field, int value) {
    _tag(field, WireType.varint);
    _varint(value);
  }

  void writeUint32(int field, int value) {
    if (value < 0) throw ArgumentError.value(value, 'value', 'uint32 must be >= 0');
    _tag(field, WireType.varint);
    _varint(value);
  }

  void writeEnum(int field, int value) => writeInt32(field, value);

  void writeBool(int field, bool value) {
    _tag(field, WireType.varint);
    _varint(value ? 1 : 0);
  }

  void writeString(int field, String value) => writeBytes(field, utf8.encode(value));

  void writeBytes(int field, List<int> value) {
    _tag(field, WireType.lengthDelimited);
    _varint(value.length);
    _out.add(value);
  }

  void writeMessage(int field, void Function(ProtoWriter) writeBody) {
    final sub = ProtoWriter();
    writeBody(sub);
    writeBytes(field, sub.takeBytes());
  }

  Uint8List takeBytes() => _out.takeBytes();
}

/// Minimal protobuf decoder. Unknown fields are skipped by the generated code.
class ProtoReader {
  ProtoReader(List<int> bytes, [int start = 0, int? end])
      : _bytes = bytes,
        _pos = start,
        _end = end ?? bytes.length;

  final List<int> _bytes;
  int _pos;
  final int _end;

  bool get isAtEnd => _pos >= _end;

  int _byte() {
    if (_pos >= _end) throw ProtoDecodeException('unexpected end of message');
    return _bytes[_pos++];
  }

  /// Reads a varint as a 64-bit integer.
  int readVarint() {
    var result = 0;
    var shift = 0;
    for (var i = 0; i < 10; i++) {
      final b = _byte();
      result |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
    }
    throw ProtoDecodeException('varint too long');
  }

  ProtoTag readTag() {
    final key = readVarint();
    final field = key >> 3;
    if (field == 0) throw ProtoDecodeException('invalid field number 0');
    return ProtoTag(field, key & 7);
  }

  int readInt32() => readVarint().toSigned(32);

  int readUint32() => readVarint().toUnsigned(32);

  bool readBool() => readVarint() != 0;

  Uint8List readBytes() {
    final len = readVarint();
    if (len < 0 || _pos + len > _end) {
      throw ProtoDecodeException('length $len exceeds message');
    }
    final out = Uint8List.fromList(_bytes.sublist(_pos, _pos + len));
    _pos += len;
    return out;
  }

  String readString() => utf8.decode(readBytes(), allowMalformed: true);

  ProtoReader readSubReader() {
    final len = readVarint();
    if (len < 0 || _pos + len > _end) {
      throw ProtoDecodeException('length $len exceeds message');
    }
    final sub = ProtoReader(_bytes, _pos, _pos + len);
    _pos += len;
    return sub;
  }

  void skip(int wireType) {
    switch (wireType) {
      case WireType.varint:
        readVarint();
      case WireType.fixed64:
        _advance(8);
      case WireType.lengthDelimited:
        _advance(readVarint());
      case WireType.fixed32:
        _advance(4);
      default:
        throw ProtoDecodeException('unsupported wire type $wireType');
    }
  }

  void _advance(int n) {
    if (n < 0 || _pos + n > _end) throw ProtoDecodeException('skip past end');
    _pos += n;
  }
}
