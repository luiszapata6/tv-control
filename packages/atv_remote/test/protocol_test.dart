import 'dart:async';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/src/message_channel.dart';
import 'package:atv_remote/src/proto/remotemessage.pb.dart';
import 'package:test/test.dart';

import 'support/fake_tv.dart';
import 'support/golden.dart';

void main() {
  late ClientIdentity identity;
  setUpAll(() async => identity = await ClientIdentity.generate(bits: 1024, inIsolate: false));

  group('pairing flow', () {
    final v = (golden['pairing'] as List).cast<Map<String, dynamic>>().first;
    final serverDer = hexBytes(v['server_cert_der'] as String);

    late FakeConnector connector;
    late String expectedCode;

    setUp(() {
      connector = FakeConnector(serverCertDer: serverDer);
      // Take nonce 0000 and derive the code (check byte) like the TV would.
      final server = CertificateInfo.parse(serverDer).publicNumbers;
      for (var check = 0; check < 256; check++) {
        final code = '${check.toRadixString(16).padLeft(2, '0').toUpperCase()}0000';
        try {
          computePairingSecret(client: identity.publicNumbers, server: server, code: code);
          expectedCode = code;
          break;
        } on AtvPairingException {
          continue;
        }
      }
      connector.onConnect = (channel, port) {
        FakePairingTv(
          channel,
          expectedSecret: () =>
              computePairingSecret(client: identity.publicNumbers, server: server, code: expectedCode),
        );
      };
    });

    test('start + finish with the right code', () async {
      final session = await PairingSession.start(host: 'tv', identity: identity, connector: connector);
      expect(session.serverName, 'Hisense 65U6GA');
      expect(session.subject!.mac, 'AA:BB:CC:DD:EE:FF');
      await session.finish(expectedCode.toLowerCase());
    });

    test('a typo keeps the session open so the user can retry', () async {
      final session = await PairingSession.start(host: 'tv', identity: identity, connector: connector);
      final typo = '${expectedCode.substring(0, 2) == 'FF' ? '00' : 'FF'}${expectedCode.substring(2)}';
      await expectLater(session.finish(typo), throwsA(isA<AtvPairingException>()));
      await session.finish(expectedCode);
    });

    test('a code the TV rejects fails with AtvPairingException', () async {
      final server = CertificateInfo.parse(serverDer).publicNumbers;
      // Self-consistent code for a different nonce.
      String? other;
      for (var n = 0; other == null; n++) {
        final nonce = n.toRadixString(16).padLeft(4, '0').toUpperCase();
        if (nonce == expectedCode.substring(2)) continue;
        for (var c = 0; c < 256; c++) {
          final code = '${c.toRadixString(16).padLeft(2, '0').toUpperCase()}$nonce';
          try {
            computePairingSecret(client: identity.publicNumbers, server: server, code: code);
            other = code;
            break;
          } on AtvPairingException {
            continue;
          }
        }
      }
      final session = await PairingSession.start(host: 'tv', identity: identity, connector: connector);
      await expectLater(session.finish(other), throwsA(isA<AtvPairingException>()));
    });

    test('connection errors surface as AtvConnectionException', () async {
      connector.failWith = const AtvConnectionException('no route');
      await expectLater(
        PairingSession.start(host: 'tv', identity: identity, connector: connector),
        throwsA(isA<AtvConnectionException>()),
      );
    });

    test('a TV that never answers times out', () async {
      connector.onConnect = (channel, port) {}; // silent TV
      await expectLater(
        PairingSession.start(
          host: 'tv',
          identity: identity,
          connector: connector,
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<AtvException>()),
      );
    });
  });

  group('remote connection', () {
    late FakeConnector connector;
    late FakeRemoteTv tv;
    late Completer<FakeRemoteTv> tvReady;

    setUp(() {
      tvReady = Completer();
      connector = FakeConnector(
        onConnect: (channel, port) {
          tv = FakeRemoteTv(channel);
          if (!tvReady.isCompleted) tvReady.complete(tv);
        },
      );
    });

    Future<AtvRemote> connect({Duration idle = const Duration(seconds: 16), int features = AtvFeature.defaults}) =>
        AtvRemote.connect(host: 'tv', identity: identity, connector: connector, idleTimeout: idle, features: features);

    test('handshake negotiates features and reports state', () async {
      final remote = await connect();
      final configure = tv.received.firstWhere((m) => m.remoteConfigure != null).remoteConfigure!;
      expect(configure.code1, AtvFeature.defaults & 622);
      expect(configure.deviceInfo!.packageName, 'atvremote');
      expect(tv.received.firstWhere((m) => m.remoteSetActive != null).remoteSetActive!.active, AtvFeature.defaults & 622);
      await Future<void>.delayed(Duration.zero);
      expect(remote.state.isOn, isTrue);
      expect(remote.state.volume, const AtvVolume(level: 18, max: 100, muted: false));
      expect(remote.state.currentApp, 'com.google.android.tvlauncher');
      expect(remote.state.deviceInfo, const AtvDeviceInfo(vendor: 'Hisense', model: '65U6GA', appVersion: '5.2'));
      expect(remote.state.supports(AtvFeature.appLink), isTrue);
      expect(remote.state.supports(AtvFeature.voice), isFalse);
      await remote.close();
    });

    test('keys, long presses, text and app links are sent as expected', () async {
      final remote = await connect();
      remote.press(AtvKey.home);
      remote.sendKey(RemoteKeyCode.KEYCODE_DPAD_CENTER, direction: KeyDirection.startLong);
      remote.sendKey(RemoteKeyCode.KEYCODE_DPAD_CENTER, direction: KeyDirection.endLong);
      remote.sendText('hola');
      remote.launchApp('com.netflix.ninja');
      remote.launchApp('https://www.youtube.com/watch?v=x');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final keys = tv.received.where((m) => m.remoteKeyInject != null).map((m) => m.remoteKeyInject!).toList();
      expect(keys.map((k) => (k.keyCode, k.direction)), [
        (RemoteKeyCode.KEYCODE_HOME, RemoteDirection.SHORT),
        (RemoteKeyCode.KEYCODE_DPAD_CENTER, RemoteDirection.START_LONG),
        (RemoteKeyCode.KEYCODE_DPAD_CENTER, RemoteDirection.END_LONG),
      ]);
      final text = tv.received.firstWhere((m) => m.remoteImeBatchEdit != null).remoteImeBatchEdit!;
      expect([text.imeCounter, text.fieldCounter], [5, 2], reason: 'counters echo what the TV sent');
      expect(text.editInfo.single.textFieldStatus!.value, 'hola');
      expect(text.editInfo.single.textFieldStatus!.start, 3);
      final links = tv.received.where((m) => m.remoteAppLinkLaunchRequest != null).map((m) => m.remoteAppLinkLaunchRequest!.appLink);
      expect(links, ['market://launch?id=com.netflix.ninja', 'https://www.youtube.com/watch?v=x']);
      expect(() => remote.sendText(''), throwsArgumentError);
      await remote.close();
    });

    test('answers pings with the same value', () async {
      final remote = await connect();
      tv.send(RemoteMessage(remotePingRequest: RemotePingRequest(val1: 77, val2: 1)));
      final pong = await tv.next((m) => m.remotePingResponse != null);
      expect(pong.remotePingResponse!.val1, 77);
      await remote.close();
    });

    test('state pushes are published once per change', () async {
      final remote = await connect();
      final states = <AtvState>[];
      remote.stateChanges.listen(states.add);
      tv.send(RemoteMessage(remoteSetVolumeLevel: RemoteSetVolumeLevel(volumeLevel: 30, volumeMax: 100, volumeMuted: true)));
      tv.send(RemoteMessage(remoteSetVolumeLevel: RemoteSetVolumeLevel(volumeLevel: 30, volumeMax: 100, volumeMuted: true)));
      tv.send(RemoteMessage(remoteStart: RemoteStart(started: false)));
      tv.send(RemoteMessage(
        remoteImeKeyInject: RemoteImeKeyInject(appInfo: RemoteAppInfo(appPackage: 'com.netflix.ninja')),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(states, hasLength(3));
      expect(remote.state.volume!.muted, isTrue);
      expect(remote.state.isOn, isFalse);
      expect(remote.state.currentApp, 'com.netflix.ninja');
      await remote.close();
    });

    test('closes itself when the TV goes silent', () async {
      final remote = await connect(idle: const Duration(milliseconds: 150));
      final reason = await remote.done.timeout(const Duration(seconds: 2));
      expect(reason, isA<AtvConnectionClosedException>());
      expect(() => remote.press(AtvKey.home), throwsA(isA<AtvConnectionClosedException>()));
    });

    test('done completes when the TV hangs up', () async {
      final remote = await connect();
      await tv.close();
      expect(await remote.done.timeout(const Duration(seconds: 2)), isA<AtvConnectionClosedException>());
    });

    test('a TV that never sends remote_start times out', () async {
      connector.onConnect = (channel, port) => FakeRemoteTv(channel, autoStart: false);
      await expectLater(
        AtvRemote.connect(host: 'tv', identity: identity, connector: connector, timeout: const Duration(milliseconds: 200)),
        throwsA(isA<AtvConnectionException>()),
      );
    });

    test('garbage from the TV is ignored', () async {
      final remote = await connect();
      tv.channel.send([0xff, 0xff, 0xff]);
      tv.send(RemoteMessage(remoteStart: RemoteStart(started: false)));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(remote.state.isOn, isFalse);
      expect(remote.isClosed, isFalse);
      await remote.close();
    });
  });

  group('MessageChannel', () {
    test('next() fails when the peer closes', () async {
      final pair = MemorySocketPair();
      final client = MessageChannel(pair.client);
      final waiting = client.next();
      await pair.server.close();
      await expectLater(waiting, throwsA(isA<AtvConnectionClosedException>()));
      expect(() => client.send([1]), throwsA(isA<AtvConnectionClosedException>()));
    });
  });
}
