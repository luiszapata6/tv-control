import 'dart:convert';
import 'dart:io';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:test/test.dart';

/// Contract tests: every example frame in fixtures/messages.json (also read
/// by the Kotlin server tests) parses and re-encodes to the same JSON.
void main() {
  final fixtures = (jsonDecode(File('fixtures/messages.json').readAsStringSync()) as Map).cast<String, dynamic>();

  for (final entry in fixtures.entries) {
    test('round trip ${entry.key}', () {
      final json = entry.value as Map<String, dynamic>;
      final frame = CompanionFrame.decode(jsonEncode(json));
      expect(jsonDecode(frame.encode()), json);
    });
  }

  test('frame kinds', () {
    expect(CompanionFrame.decode(jsonEncode(fixtures['hello'])), isA<RequestFrame>());
    expect(CompanionFrame.decode(jsonEncode(fixtures['hello_ok'])), isA<ResultFrame>());
    expect(CompanionFrame.decode(jsonEncode(fixtures['bad_code'])), isA<ErrorFrame>());
    expect(CompanionFrame.decode(jsonEncode(fixtures['event_layout'])), isA<EventFrame>());
  });

  test('models parse their fixtures', () {
    Map<String, dynamic> data(String name) => (fixtures[name] as Map)['data'] as Map<String, dynamic>;
    final apps = (data('apps_list_result')['apps'] as List).map((a) => CompanionApp.fromJson(a as Map<String, dynamic>));
    expect(apps.first.label, 'YouTube');
    expect(apps.last.isSystem, isTrue);
    final layout = LauncherLayout.fromJson(data('launcher_result')['layout'] as Map<String, dynamic>);
    expect(layout.order, hasLength(2));
    expect(layout.hidden, ['com.example.junk']);
    final np = NowPlaying.fromJson(data('now_playing_result')['nowPlaying'] as Map<String, dynamic>);
    expect(np.state, PlaybackState.playing);
    expect(np.progress, closeTo(61 / 3600, 1e-9));
    final usage = UsageReport.fromJson(data('usage_result'));
    expect(usage.entries.single.foreground, const Duration(hours: 2));
    final backup = LauncherBackup.fromJson(data('backup_result')['backup'] as Map<String, dynamic>);
    expect(backup.layout, layout);
    final server = ServerInfo.fromJson((data('pair_token')['server'] as Map).cast<String, dynamic>());
    expect(server.deviceId, 'a1b2c3');
    expect((CompanionFrame.decode(jsonEncode(fixtures['busy'])) as ErrorFrame).code, CompanionErrorCode.busy);
    expect(TvInput.fromJson((data('inputs_result')['inputs'] as List).first as Map<String, dynamic>).kind, InputKind.hdmi);
  });

  test('malformed frames are rejected', () {
    expect(() => CompanionFrame.decode('[]'), throwsFormatException);
    expect(() => CompanionFrame.decode('{"id":1}'), throwsFormatException);
    expect(() => CompanionFrame.decode('{"type":"result"}'), throwsFormatException);
    expect(() => CompanionFrame.decode('{"type":"ping","id":"x"}'), throwsFormatException);
    expect(() => CompanionFrame.decode('nope'), throwsFormatException);
  });

  group('layout editing', () {
    const base = LauncherLayout(order: ['a', 'b', 'c'], hidden: ['x']);
    test('pin, unpin, move', () {
      expect(base.pin('x').order, ['a', 'b', 'c', 'x']);
      expect(base.pin('x').hidden, isEmpty);
      expect(base.pin('c', index: 0).order, ['c', 'a', 'b']);
      expect(base.unpin('b').order, ['a', 'c']);
      expect(base.move(0, 2).order, ['b', 'c', 'a']);
      expect(base.move(9, 0), base);
    });
    test('columns are clamped', () {
      expect(base.copyWith(columns: 20).columns, LauncherLayout.maxColumns);
      expect(LauncherLayout.fromJson({'columns': 1}).columns, LauncherLayout.minColumns);
    });
  });
}
