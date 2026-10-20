@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atv_remote/atv_remote.dart';
import 'package:test/test.dart';

/// End-to-end tests over real TLS against the simulated TV in tools/sim
/// (itself validated against the reference Python client).
///
/// Set ATV_SIM_PYTHON to a Python with tools/sim/requirements.txt installed.
void main() {
  final python = Platform.environment['ATV_SIM_PYTHON'];
  if (python == null) {
    test('simulator integration', () {}, skip: 'set ATV_SIM_PYTHON to run against the simulated TV');
    return;
  }

  late Process sim;
  late int pairingPort;
  late int remotePort;
  late Directory dir;
  late File codeFile;
  late File eventsFile;
  final acks = StreamController<String>.broadcast();

  Future<void> control(String command) async {
    final ack = acks.stream.first.timeout(const Duration(seconds: 5));
    sim.stdin.writeln(command);
    await sim.stdin.flush();
    await ack;
  }

  List<Map<String, dynamic>> events() => eventsFile.existsSync()
      ? eventsFile.readAsLinesSync().map((l) => jsonDecode(l) as Map<String, dynamic>).toList()
      : [];

  Future<Map<String, dynamic>> waitEvent(String kind, [bool Function(Map<String, dynamic>)? where]) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      for (final e in events()) {
        if (e['kind'] == kind && (where == null || where(e))) return e;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('no $kind event; got ${events().map((e) => e['kind']).toList()}');
  }

  Future<String> waitCode() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (codeFile.existsSync() && codeFile.readAsStringSync().length == 6) return codeFile.readAsStringSync();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('no pairing code');
  }

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('atv_sim');
    codeFile = File('${dir.path}/code.txt');
    eventsFile = File('${dir.path}/events.jsonl');
    sim = await Process.start(
      python,
      [
        '-m', 'atv_sim',
        '--pairing-port', '0',
        '--remote-port', '0',
        '--ping-interval', '0.5',
        '--state-dir', '${dir.path}/state',
        '--code-file', codeFile.path,
        '--events-file', eventsFile.path,
        '--control-stdin',
      ],
      workingDirectory: '../../tools/sim',
    );
    sim.stderr.transform(utf8.decoder).listen(stderr.write);
    final lines = sim.stdout.transform(utf8.decoder).transform(const LineSplitter()).asBroadcastStream();
    final ports = jsonDecode(await lines.first.timeout(const Duration(seconds: 20))) as Map<String, dynamic>;
    pairingPort = ports['pairing_port'] as int;
    remotePort = ports['remote_port'] as int;
    lines.listen((l) {
      final m = jsonDecode(l) as Map<String, dynamic>;
      if (m.containsKey('ack')) acks.add(m['ack'] as String);
    });
  });

  tearDownAll(() async {
    sim.kill();
    await sim.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => -1);
    await dir.delete(recursive: true);
  });

  late ClientIdentity identity;

  test('pairs with the code the TV shows', () async {
    identity = await ClientIdentity.generate(commonName: 'TV Control');
    final session = await PairingSession.start(
      host: '127.0.0.1',
      port: pairingPort,
      identity: identity,
      clientName: 'TV Control iPhone',
    );
    expect(session.serverName, 'Hisense 65U6GA');
    expect(session.subject!.mac, 'AA:BB:CC:DD:EE:FF');
    await session.finish(await waitCode());
    final req = await waitEvent('pairing_request');
    expect(req['client_name'], 'TV Control iPhone');
    await waitEvent('paired');
  });

  test('reads name and MAC without pairing', () async {
    final r = await fetchTvCertificate(host: '127.0.0.1', port: pairingPort, identity: identity);
    expect(r.subject!.name, 'Hisense 65U6GA');
  });

  test('connects, reads state and drives the TV', () async {
    final remote = await AtvRemote.connect(host: '127.0.0.1', port: remotePort, identity: identity);
    addTearDown(remote.close);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(remote.state.isOn, isTrue);
    expect(remote.state.volume, const AtvVolume(level: 18, max: 100, muted: false));
    expect(remote.state.currentApp, 'com.google.android.tvlauncher');
    expect(remote.state.deviceInfo!.vendor, 'Hisense');

    remote.press(AtvKey.down);
    remote.press(AtvKey.volumeUp);
    remote.sendKey(RemoteKeyCode.KEYCODE_DPAD_CENTER, direction: KeyDirection.startLong);
    remote.sendKey(RemoteKeyCode.KEYCODE_DPAD_CENTER, direction: KeyDirection.endLong);
    remote.launchApp('com.netflix.ninja');
    remote.sendText('pastor alemán');

    await waitEvent('key', (e) => e['key'] == 'KEYCODE_DPAD_DOWN' && e['direction'] == 'SHORT');
    await waitEvent('key', (e) => e['key'] == 'KEYCODE_DPAD_CENTER' && e['direction'] == 'END_LONG');
    await waitEvent('app_link', (e) => e['link'] == 'market://launch?id=com.netflix.ninja');
    await waitEvent('text', (e) => e['text'] == 'pastor alemán');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(remote.state.volume!.level, 19);
    expect(remote.state.currentApp, 'com.netflix.ninja');
  });

  test('receives changes made on the TV and answers pings', () async {
    final remote = await AtvRemote.connect(host: '127.0.0.1', port: remotePort, identity: identity);
    addTearDown(remote.close);
    final next = remote.stateChanges.firstWhere((s) => s.volume?.level == 42);
    await control('volume 42');
    await next.timeout(const Duration(seconds: 3));
    final off = remote.stateChanges.firstWhere((s) => s.isOn == false);
    await control('power off');
    await off.timeout(const Duration(seconds: 3));
    await control('power on');
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(remote.isClosed, isFalse, reason: 'pings keep the connection alive');
    expect(events().where((e) => e['kind'] == 'pong'), isNotEmpty);
  });

  test('client reconnects after the TV drops the connection', () async {
    final client = AtvClient(
      host: '127.0.0.1',
      port: remotePort,
      identity: identity,
      initialBackoff: const Duration(milliseconds: 50),
    )..start();
    addTearDown(client.dispose);
    await client.statusChanges.firstWhere((s) => s == AtvConnectionStatus.connected).timeout(const Duration(seconds: 5));
    final reconnected = client.statusChanges
        .where((s) => s == AtvConnectionStatus.connected)
        .first
        .timeout(const Duration(seconds: 8));
    await control('disconnect');
    await reconnected;
    client.press(AtvKey.home);
    await waitEvent('key', (e) => e['key'] == 'KEYCODE_HOME');
  });

  test('an unknown identity is rejected and needs pairing', () async {
    final stranger = await ClientIdentity.generate();
    await expectLater(
      AtvRemote.connect(host: '127.0.0.1', port: remotePort, identity: stranger),
      throwsA(anyOf(isA<AtvAuthException>(), isA<AtvHandshakeException>(), isA<AtvConnectionClosedException>())),
    );
    final client = AtvClient(host: '127.0.0.1', port: remotePort, identity: stranger)..start();
    addTearDown(client.dispose);
    final status = await client.statusChanges
        .firstWhere((s) => s == AtvConnectionStatus.needsPairing)
        .timeout(const Duration(seconds: 10));
    expect(status, AtvConnectionStatus.needsPairing, reason: 'TLS rejection must map to needsPairing');
  });

  test('a wrong code is rejected by the TV', () async {
    final other = await ClientIdentity.generate();
    if (codeFile.existsSync()) codeFile.deleteSync();
    final session = await PairingSession.start(host: '127.0.0.1', port: pairingPort, identity: other);
    final code = await waitCode();
    // Self-consistent code for another nonce so the TV (not the check byte) rejects it.
    final server = session.serverInfo.publicNumbers;
    final nonce = ((int.parse(code.substring(2), radix: 16) + 1) % 0x10000).toRadixString(16).padLeft(4, '0');
    String? wrong;
    for (var c = 0; c < 256 && wrong == null; c++) {
      final candidate = '${c.toRadixString(16).padLeft(2, '0')}$nonce';
      try {
        computePairingSecret(client: other.publicNumbers, server: server, code: candidate);
        wrong = candidate;
      } on AtvPairingException {
        // keep looking
      }
    }
    await expectLater(session.finish(wrong!), throwsA(isA<AtvPairingException>()));
    await waitEvent('pairing_failed');
  });
}
