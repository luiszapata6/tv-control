import 'package:atv_remote/atv_remote.dart';
import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/src/services/devices.dart';
import 'package:tv_remote/src/services/storage.dart';
import 'package:tv_remote/src/services/tv_session.dart';

import 'support.dart';

void main() {
  late ClientIdentity identity;
  setUpAll(() async => identity = await ClientIdentity.generate(bits: 512, inIsolate: false));

  const tv = SavedTv(id: 'AA:BB:CC:DD:EE:FF', name: 'Sala', host: '192.168.1.50', mac: 'AA:BB:CC:DD:EE:FF');

  Future<(TvSession, FakeTvEnv, List<(String, String)>)> start({CompanionConnector? companion, DeviceStore? store}) async {
    final env = FakeTvEnv(identity);
    final wakes = <(String, String)>[];
    final devices = store ?? DeviceStore(settings: MemorySettingsStore(), secrets: MemorySecretStore(), identity: identity);
    final s = TvSession(
      tv: tv,
      identity: identity,
      devices: devices,
      clientFactory: env.client,
      companionConnector: companion ?? noCompanion,
      wake: (mac, host) async => wakes.add((mac, host)),
      keyInterval: Duration.zero,
    );
    await s.start();
    for (var i = 0; i < 100 && !s.isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return (s, env, wakes);
  }

  test('connects and mirrors the TV state', () async {
    final (s, _, _) = await start();
    expect(s.isConnected, isTrue);
    expect(s.volume?.level, 18);
    expect(s.currentAppLabel, 'Inicio');
    s.dispose();
  });

  test('volume drag steps the TV towards the target', () async {
    final (s, env, _) = await start();
    s.setVolume(22);
    expect(s.displayVolume, 22, reason: 'slider shows the target at once');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(env.keyNames.where((k) => k == 'KEYCODE_VOLUME_UP'), hasLength(4));
    s.setVolume(16);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(env.keyNames.where((k) => k == 'KEYCODE_VOLUME_DOWN'), hasLength(2), reason: 'from 18 (TV value) to 16');
    s.dispose();
  });

  test('text mirroring: full text, then deletes when cleared', () async {
    final (s, env, _) = await start();
    expect(s.setText('hola'), isTrue);
    expect(s.setText(''), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final texts = env.tv.received.where((m) => m.remoteImeBatchEdit != null).toList();
    expect(texts.single.remoteImeBatchEdit!.editInfo.single.textFieldStatus!.value, 'hola');
    expect(env.keyNames.where((k) => k == 'KEYCODE_DEL'), hasLength(4));
    s.dispose();
  });

  test('power wakes the TV over the network when it is not connected', () async {
    final env = FakeTvEnv(identity);
    env.connector.failWith = const AtvConnectionException('off');
    final wakes = <(String, String)>[];
    final s = TvSession(
      tv: tv,
      identity: identity,
      devices: DeviceStore(settings: MemorySettingsStore(), secrets: MemorySecretStore(), identity: identity),
      clientFactory: env.client,
      companionConnector: noCompanion,
      wake: (mac, host) async => wakes.add((mac, host)),
    );
    await s.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(s.status, AtvConnectionStatus.unreachable);
    expect(await s.power(), isTrue);
    expect(wakes, [('AA:BB:CC:DD:EE:FF', '192.168.1.50')]);
    expect(s.press(AtvKey.home), isFalse);
    s.dispose();
  });

  test('without the launcher, apps fall back to well-known ones and app links', () async {
    final (s, env, _) = await start();
    expect(s.companionStatus, CompanionStatus.unavailable);
    final yt = s.apps.firstWhere((a) => a.label == 'YouTube');
    expect(await s.launch(yt), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final links = env.tv.received.where((m) => m.remoteAppLinkLaunchRequest != null).map((m) => m.remoteAppLinkLaunchRequest!.appLink);
    expect(links, ['https://www.youtube.com']);
    s.dispose();
  });

  test('companion: pairing, real apps, launching and layout', () async {
    final companion = FakeCompanion();
    final store = DeviceStore(settings: MemorySettingsStore(), secrets: MemorySecretStore(), identity: identity);
    final (s, _, _) = await start(companion: companion.connect, store: store);
    expect(s.companionStatus, CompanionStatus.needsPairing);
    await s.requestCompanionPairing();
    expect(s.companionStatus, CompanionStatus.pairing);
    await expectLater(s.confirmCompanionPairing('000000'), throwsA(isA<CompanionException>()));
    await s.confirmCompanionPairing('482915');
    expect(s.companionStatus, CompanionStatus.connected);
    expect(await store.companionToken(tv.id), 'tok');
    expect(s.apps.map((a) => a.label), ['Netflix', 'Plex']);
    expect(s.pinnedApps.map((a) => a.label), ['Netflix']);
    expect(s.nowPlaying?.title, 'Serie');
    expect(await s.launch(s.apps.last), isTrue);
    expect(companion.launched, ['com.plexapp.android']);
    expect(await s.icon('com.plexapp.android'), [1, 2, 3]);
    await s.pin('com.plexapp.android');
    expect(companion.layout.order, ['com.netflix.ninja', 'com.plexapp.android']);
    await s.reorder(1, 0);
    expect(companion.layout.order, ['com.plexapp.android', 'com.netflix.ninja']);
    s.dispose();
  });

  test('companion: a stored token connects directly', () async {
    final companion = FakeCompanion();
    final store = DeviceStore(settings: MemorySettingsStore(), secrets: MemorySecretStore(), identity: identity);
    await store.setCompanionToken(tv.id, 'tok');
    final (s, _, _) = await start(companion: companion.connect, store: store);
    expect(s.companionStatus, CompanionStatus.connected);
    s.dispose();
  });

  group('device store', () {
    test('save, select, remove and persist', () async {
      final settings = MemorySettingsStore();
      final secrets = MemorySecretStore();
      final store = DeviceStore(settings: settings, secrets: secrets, identity: identity);
      await store.save(tv);
      await store.save(const SavedTv(id: 'b', name: 'Cuarto', host: '192.168.1.60'));
      expect(store.selected?.name, 'Cuarto');
      await store.setCompanionToken('b', 'x');
      final reloaded = DeviceStore(settings: settings, secrets: secrets, identity: identity);
      await reloaded.load();
      expect(reloaded.tvs.map((t) => t.name), ['Sala', 'Cuarto']);
      expect(reloaded.selected?.id, 'b');
      await reloaded.remove('b');
      expect(reloaded.selected?.id, tv.id);
      expect(await reloaded.companionToken('b'), isNull);
    });

    test('identity is generated once and kept in the secret store', () async {
      final secrets = MemorySecretStore();
      final store = DeviceStore(settings: MemorySettingsStore(), secrets: secrets, identityBits: 512);
      final a = await store.identity();
      final again = DeviceStore(settings: MemorySettingsStore(), secrets: secrets, identityBits: 512);
      expect((await again.identity()).publicNumbers, a.publicNumbers);
    });
  });
}
