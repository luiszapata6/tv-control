import 'dart:async';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/testing.dart';
import 'package:test/test.dart';


void main() {
  late ClientIdentity identity;
  setUpAll(() async => identity = await ClientIdentity.generate(bits: 1024, inIsolate: false));

  Future<AtvConnectionStatus> waitFor(AtvClient c, AtvConnectionStatus s) async {
    if (c.status == s) return s;
    return c.statusChanges.firstWhere((x) => x == s).timeout(const Duration(seconds: 3));
  }

  test('connects, forwards state and commands', () async {
    late FakeRemoteTv tv;
    final connector = FakeConnector(onConnect: (ch, _) => tv = FakeRemoteTv(ch));
    final client = AtvClient(host: 'tv', identity: identity, connector: connector)..start();
    await waitFor(client, AtvConnectionStatus.connected);
    expect(client.isConnected, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(client.state.volume?.level, 18);
    client.press(AtvKey.volumeUp);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(tv.received.where((m) => m.remoteKeyInject != null), hasLength(1));
    await client.dispose();
  });

  test('reconnects after the TV drops the connection', () async {
    final tvs = <FakeRemoteTv>[];
    final connector = FakeConnector(onConnect: (ch, _) => tvs.add(FakeRemoteTv(ch)));
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connector: connector,
      initialBackoff: const Duration(milliseconds: 10),
    )..start();
    await waitFor(client, AtvConnectionStatus.connected);
    await tvs.single.close();
    await waitFor(client, AtvConnectionStatus.unreachable);
    await waitFor(client, AtvConnectionStatus.connected);
    expect(connector.connects, 2);
    await client.dispose();
  });

  test('backs off while unreachable and retryNow skips the wait', () async {
    final connector = FakeConnector(onConnect: (ch, _) => FakeRemoteTv(ch))
      ..failWith = const AtvConnectionException('down');
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connector: connector,
      initialBackoff: const Duration(seconds: 30),
    )..start();
    await waitFor(client, AtvConnectionStatus.unreachable);
    expect(connector.connects, 1);
    connector.failWith = null;
    client.retryNow();
    await waitFor(client, AtvConnectionStatus.connected);
    expect(connector.connects, 2);
    expect(() => client.press(AtvKey.home), returnsNormally);
    await client.dispose();
  });

  test('stops and reports needsPairing when the TV rejects the identity', () async {
    final connector = FakeConnector()..failWith = const AtvAuthException('unknown cert');
    final client = AtvClient(host: 'tv', identity: identity, connector: connector)..start();
    await waitFor(client, AtvConnectionStatus.needsPairing);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(connector.connects, 1, reason: 'no retries without pairing');
    expect(client.lastError, isA<AtvAuthException>());
    await client.dispose();
  });

  test('commands while disconnected throw a clear error', () async {
    final client = AtvClient(host: 'tv', identity: identity, connector: FakeConnector());
    expect(() => client.press(AtvKey.home), throwsA(isA<AtvConnectionClosedException>()));
    expect(client.status, AtvConnectionStatus.idle);
    await client.dispose();
  });

  test('stop() closes the connection and goes idle', () async {
    late FakeRemoteTv tv;
    final connector = FakeConnector(onConnect: (ch, _) => tv = FakeRemoteTv(ch));
    final client = AtvClient(host: 'tv', identity: identity, connector: connector)..start();
    await waitFor(client, AtvConnectionStatus.connected);
    await client.stop();
    expect(client.status, AtvConnectionStatus.idle);
    expect(await tv.channel.closed.timeout(const Duration(seconds: 2)), isA<AtvException>());
    await client.dispose();
  });
}
