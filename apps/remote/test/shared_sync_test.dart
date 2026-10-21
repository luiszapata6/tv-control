import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/src/services/devices.dart';
import 'package:tv_remote/src/services/shared_bridge.dart';
import 'package:tv_remote/src/services/storage.dart';
import 'package:tv_remote/src/services/tv_session.dart';

import 'support.dart';

class RecordingBridge implements SharedBridge {
  final calls = <String>[];
  SharedStatusData? status;
  List<RemoteApp> apps = const [];
  bool? activity;

  @override
  Future<void> setTv(SavedTv tv, ClientIdentity identity) async => calls.add('setTv:${tv.name}');
  @override
  Future<void> clearTv() async => calls.add('clearTv');
  @override
  Future<void> setApps(List<RemoteApp> a) async {
    calls.add('setApps');
    apps = a;
  }

  @override
  Future<void> updateStatus(SharedStatusData s) async {
    calls.add('status');
    status = s;
  }

  @override
  Future<void> setLiveActivity(bool enabled) async {
    calls.add('activity:$enabled');
    activity = enabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ClientIdentity identity;
  setUpAll(() async => identity = await ClientIdentity.generate(bits: 512, inIsolate: false));
  const tv = SavedTv(id: 'AA:BB:CC:DD:EE:FF', name: 'Sala', host: '192.168.1.50', mac: 'AA:BB:CC:DD:EE:FF');

  Future<TvSession> connected() async {
    final env = FakeTvEnv(identity);
    final s = TvSession(
      tv: tv,
      identity: identity,
      devices: DeviceStore(settings: MemorySettingsStore(), secrets: MemorySecretStore(), identity: identity),
      clientFactory: env.client,
      companionConnector: noCompanion,
      keyInterval: Duration.zero,
    );
    await s.start();
    for (var i = 0; i < 100 && !s.isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return s;
  }

  test('mirrors TV, status, apps and the Live Activity, sending only changes', () async {
    final s = await connected();
    final bridge = RecordingBridge();
    final live = ValueNotifier(true);
    final sync = SharedSync(bridge, s, identity, liveActivity: live);
    await Future<void>.delayed(Duration.zero);
    expect(bridge.calls.first, 'setTv:Sala');
    expect(bridge.status?.connected, isTrue);
    expect(bridge.status?.volume, 18);
    expect(bridge.apps, isNotEmpty);
    expect(bridge.activity, isTrue);

    final before = bridge.calls.length;
    sync.refresh(); // nothing changed
    await Future<void>.delayed(Duration.zero);
    expect(bridge.calls.length, before);

    live.value = false;
    sync.refresh();
    expect(bridge.activity, isFalse);

    live.value = true;
    sync.refresh();
    sync.dispose();
    expect(bridge.activity, isFalse, reason: 'ending the session ends the activity');
    s.dispose();
  });

  test('method channel bridge is a no-op off iOS and tolerates a missing plugin', () async {
    const channel = MethodChannel('tvcontrol/shared');
    final seen = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      seen.add(c.method);
      return null;
    });
    final bridge = MethodChannelSharedBridge(channel);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await bridge.clearTv();
    expect(seen, isEmpty);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await bridge.setTv(tv, identity);
    await bridge.updateStatus(const SharedStatusData(connected: true, appLabel: 'YouTube', volume: 3));
    expect(seen, ['setTv', 'updateStatus']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await bridge.clearTv(); // MissingPluginException swallowed
    debugDefaultTargetPlatformOverride = null;
  });
}
