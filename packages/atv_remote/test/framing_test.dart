import 'package:atv_remote/atv_remote.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

void main() {
  final g = goldenSection('framing');

  test('frames match the reference', () {
    expect(toHex(frameMessage([])), g['empty']);
    expect(toHex(frameMessage([1, 2, 3])), g['short']);
    expect(toHex(frameMessage(List.filled(300, 0))).substring(0, 8), g['long_300']);
  });

  test('messages split at every byte are reassembled', () {
    final stream = [...frameMessage(List.filled(200, 7)), ...frameMessage([1, 2]), ...frameMessage([])];
    final d = MessageDeframer();
    final out = <List<int>>[];
    for (final b in stream) {
      out.addAll(d.add([b]));
    }
    expect(out.map((m) => m.length), [200, 2, 0]);
    expect(out[1], [1, 2]);
    expect(d.pendingBytes, 0);
  });

  test('several messages in one chunk', () {
    final d = MessageDeframer();
    expect(d.add([...frameMessage([9]), ...frameMessage([8, 8])]).map((m) => m.toList()), [
      [9],
      [8, 8],
    ]);
  });

  test('oversized and malformed lengths are rejected', () {
    expect(() => MessageDeframer().add([0xff, 0xff, 0xff, 0xff, 0xff, 0x01]), throwsA(isA<AtvProtocolException>()));
    expect(() => MessageDeframer().add([0x81, 0x80, 0x80, 0x01]), throwsA(isA<AtvProtocolException>()));
  });
}
