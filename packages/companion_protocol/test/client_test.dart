import 'dart:async';
import 'dart:io';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:test/test.dart';

import 'support/fake_server.dart';

void main() {
  late FakeCompanionServer server;
  setUp(() => server = FakeCompanionServer());

  Future<CompanionClient> connect({String? token, Duration timeout = const Duration(seconds: 2)}) =>
      CompanionClient.connect('tv', token: token, channelFactory: server.connect, requestTimeout: timeout);

  test('a stored token authenticates immediately', () async {
    final c = await connect(token: 'secret-token');
    expect(c.authenticated, isTrue);
    expect(c.server!.name, 'Hisense 65U6GA');
    await c.close();
  });

  test('without a token the client pairs with the code on the TV', () async {
    final c = await connect();
    expect(c.authenticated, isFalse);
    await expectLater(c.listApps(), throwsA(isA<CompanionException>().having((e) => e.needsPairing, 'needsPairing', true)));
    await c.requestPairing();
    await expectLater(c.confirmPairing('000000'), throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'bad_code')));
    expect(await c.confirmPairing(' 482915 '), 'secret-token');
    expect(c.authenticated, isTrue);
    expect(await c.listApps(), hasLength(2));
    await c.close();
  });

  test('too many wrong codes lock pairing', () async {
    final c = await connect();
    for (var i = 0; i < CompanionProtocol.maxFailedCodes; i++) {
      await expectLater(c.confirmPairing('111111'), throwsA(isA<CompanionException>()));
    }
    await expectLater(c.confirmPairing('482915'), throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'locked')));
    await c.close();
  });

  group('authenticated', () {
    late CompanionClient c;
    setUp(() async => c = await connect(token: 'secret-token'));
    tearDown(() => c.close());

    test('apps, icons and launching', () async {
      final apps = await c.listApps();
      expect(apps.first.package, 'com.google.android.youtube.tv');
      expect(await c.icon('com.netflix.ninja'), [0x89, 0x50, 0x4e, 0x47]);
      final fg = c.events.firstWhere((e) => e.event == CompanionEvent.foregroundApp);
      await c.launch('com.netflix.ninja');
      expect((await fg).package, 'com.netflix.ninja');
      expect(server.launched, ['com.netflix.ninja']);
      await expectLater(c.launch('missing.app'), throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'not_found')));
    });

    test('layout round trip and change event', () async {
      final layout = await c.getLayout();
      final changed = c.events.firstWhere((e) => e.event == CompanionEvent.layoutChanged);
      final saved = await c.setLayout(layout.pin('com.netflix.ninja', index: 0).copyWith(columns: 5));
      expect(saved.order.first, 'com.netflix.ninja');
      expect(saved.columns, 5);
      expect((await changed).layout, saved);
    });

    test('inputs, now playing, usage, backup, ping', () async {
      expect((await c.listInputs()).single.kind, InputKind.hdmi);
      await c.openInput('hdmi1');
      expect(await c.nowPlaying(), isNull);
      expect((await c.usage(days: 99)).entries.single.label, 'Netflix');
      final backup = await c.exportBackup();
      final restored = await c.importBackup(LauncherBackup(layout: backup.layout.unpin('com.google.android.youtube.tv'), exportedAt: DateTime.now()));
      expect(restored.order, isEmpty);
      expect((await c.ping()).year, greaterThan(2000));
    });

    test('requests time out', () async {
      final slow = await connect(token: 'secret-token', timeout: const Duration(milliseconds: 100));
      server.dropNextRequest = true;
      await expectLater(slow.ping(), throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'timeout')));
      await slow.close();
    });

    test('pending requests fail when the TV disconnects', () async {
      server.dropNextRequest = true;
      final pending = c.ping();
      await server.dropAll();
      await expectLater(pending, throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'disconnected')));
      await c.done.timeout(const Duration(seconds: 1));
      expect(c.isClosed, isTrue);
    });
  });

  test('real WebSocket against a local server', () async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      ws.listen((text) {
        final f = CompanionFrame.decode(text as String) as RequestFrame;
        ws.add(ResultFrame(f.id!, {'authenticated': true}).encode());
      });
    });
    final c = await CompanionClient.connect('127.0.0.1', port: http.port, token: 't');
    expect(c.authenticated, isTrue);
    await c.close();
    await http.close(force: true);
  });

  test('unreachable TV fails with disconnected', () async {
    await expectLater(
      CompanionClient.connect('127.0.0.1', port: 1),
      throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'disconnected')),
    );
  });
}
