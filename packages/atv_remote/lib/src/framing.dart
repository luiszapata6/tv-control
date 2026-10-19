import 'dart:typed_data';

import 'errors.dart';
import 'proto/wire.dart';

/// Largest message we accept. Real messages are a few hundred bytes; voice
/// payloads are capped at 20 KiB by the protocol.
const int maxFrameLength = 1 << 20;

/// Prefixes [payload] with its varint length, as both protocol ports expect.
Uint8List frameMessage(List<int> payload) {
  final out = BytesBuilder(copy: false);
  ProtoWriter.encodeVarint(payload.length, out.addByte);
  out.add(payload);
  return out.takeBytes();
}

/// Splits a TCP byte stream into length-delimited messages. A chunk may hold a
/// partial message, several messages, or split the varint itself.
class MessageDeframer {
  final BytesBuilder _buffer = BytesBuilder(copy: true);

  /// Feeds [chunk] and returns every message completed by it.
  List<Uint8List> add(List<int> chunk) {
    _buffer.add(chunk);
    var bytes = _buffer.takeBytes();
    final messages = <Uint8List>[];
    var pos = 0;
    while (pos < bytes.length) {
      var length = 0;
      var shift = 0;
      var i = pos;
      var complete = false;
      while (i < bytes.length) {
        final b = bytes[i++];
        length |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) {
          complete = true;
          break;
        }
        shift += 7;
        if (shift > 28) {
          throw const AtvProtocolException('frame length varint too long');
        }
      }
      if (!complete) break;
      if (length > maxFrameLength) {
        throw AtvProtocolException('frame of $length bytes exceeds the limit');
      }
      if (bytes.length - i < length) break;
      messages.add(Uint8List.sublistView(bytes, i, i + length));
      pos = i + length;
    }
    if (pos < bytes.length) {
      _buffer.add(Uint8List.sublistView(bytes, pos));
    }
    bytes = Uint8List(0);
    return messages;
  }

  /// Bytes received that do not form a complete message yet.
  int get pendingBytes => _buffer.length;
}
