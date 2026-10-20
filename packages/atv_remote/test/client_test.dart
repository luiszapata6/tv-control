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

  test('repeated handshake drops end in needsPairing, a single one does not', () async {
    final connector = FakeConnector(onConnect: (ch, _) => FakeRemoteTv(ch))
      ..failWith = const AtvHandshakeException('reset during handshake');
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connector: connector,
      initialBackoff: const Duration(milliseconds: 5),
    )..start();
    await waitFor(client, AtvConnectionStatus.unreachable);
    expect(client.status, isNot(AtvConnectionStatus.needsPairing));
    await waitFor(client, AtvConnectionStatus.needsPairing);
    expect(connector.connects, AtvClient.handshakeFailuresBeforePairing);
    await client.dispose();
  });

  test('a handshake drop followed by success resets the counter', () async {
    final connector = FakeConnector(onConnect: (ch, _) => FakeRemoteTv(ch))
      ..failWith = const AtvHandshakeException('reset');
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connector: connector,
      initialBackoff: const Duration(milliseconds: 5),
    )..start();
    await waitFor(client, AtvConnectionStatus.unreachable);
    connector.failWith = null;
    await waitFor(client, AtvConnectionStatus.connected);
    await client.dispose();
  });

  test('an unexpected error does not kill the reconnect loop', () async {
    final connector = FakeConnector(onConnect: (ch, _) => FakeRemoteTv(ch))..failWith = StateError('boom');
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connector: connector,
      initialBackoff: const Duration(milliseconds: 5),
    )..start();
    await waitFor(client, AtvConnectionStatus.unreachable);
    expect(client.lastError, isA<AtvConnectionException>());
    connector.failWith = null;
    await waitFor(client, AtvConnectionStatus.connected);
    await client.dispose();
  });

  test('stop() then start() during a pending connect keeps a single connection', () async {
    final gate = Completer<void>();
    var connects = 0;
    final tvs = <FakeRemoteTv>[];
    final connector = FakeConnector(onConnect: (ch, _) => tvs.add(FakeRemoteTv(ch)));
    final client = AtvClient(
      host: 'tv',
      identity: identity,
      connect: () async {
        connects++;
        if (connects == 1) await gate.future;
        return AtvRemote.connect(host: 'tv', identity: identity, connector: connector);
      },
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await client.stop();
    client.start();
    await waitFor(client, AtvConnectionStatus.connected);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(client.isConnected, isTrue);
    expect(connects, 2);
    // The stale loop closed the connection it finished opening.
    expect(tvs, hasLength(2));
    // tvs.first: the new loop's live connection; tvs.last: opened late by the
    // stale loop, which must close it.
    expect(tvs.first.channel.isClosed, isFalse);
    expect(tvs.last.channel.isClosed, isTrue);
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
