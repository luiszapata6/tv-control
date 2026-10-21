import 'dart:async';
import 'dart:convert';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/testing.dart';
import 'package:companion_protocol/companion_protocol.dart';
import 'package:tv_remote/src/services/devices.dart';
import 'package:tv_remote/src/services/dictation.dart';
import 'package:tv_remote/src/services/discovery.dart';
import 'package:tv_remote/src/services/services.dart';
import 'package:tv_remote/src/services/storage.dart';
import 'package:tv_remote/src/services/tv_session.dart';

/// A fake TV reachable through in-memory sockets.
class FakeTvEnv {
  FakeTvEnv(this.identity);

  final ClientIdentity identity;
  final tvs = <FakeRemoteTv>[];
  late final connector = FakeConnector(onConnect: (ch, _) => tvs.add(FakeRemoteTv(ch)));

  FakeRemoteTv get tv => tvs.last;

  AtvClient client(SavedTv tv, ClientIdentity id) =>
      AtvClient(host: tv.host, identity: id, connector: connector, initialBackoff: const Duration(milliseconds: 20));

  List<RemoteKeyInject> get keys =>
      [for (final t in tvs) ...t.received.where((m) => m.remoteKeyInject != null).map((m) => m.remoteKeyInject!)];

  List<String> get keyNames => [for (final k in keys) k.keyCode!.name];
}

class FakeDiscovery implements TvDiscovery {
  final controller = StreamController<List<DiscoveredTv>>.broadcast();

  @override
  Stream<List<DiscoveredTv>> watch() => controller.stream;
}

class FakeDictation implements Dictation {
  void Function(String, bool)? onText;
  bool allowed = true;
  bool stopped = false;

  @override
  Future<bool> start(void Function(String text, bool isFinal) onText) async {
    this.onText = onText;
    return allowed;
  }

  @override
  Future<void> stop() async => stopped = true;
}

/// A valid 1×1 PNG, so icons decode in widget tests.
const onePixelPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

/// Minimal companion server: answers like the launcher.
class FakeCompanion {
  FakeCompanion({this.token = 'tok'});
  final String token;
  final launched = <String>[];
  LauncherLayout layout = const LauncherLayout(order: ['com.netflix.ninja']);
  String code = '482915';
  final _sinks = <StreamController<String>>[];

  Future<CompanionClient> connect(String host, String? token) {
    return CompanionClient.connect(host, token: token, channelFactory: (_) async {
      final toClient = StreamController<String>();
      final toServer = StreamController<String>();
      _sinks.add(toClient);
      var authed = false;
      toServer.stream.listen((text) {
        final f = CompanionFrame.decode(text) as RequestFrame;
        void ok([Map<String, dynamic> d = const {}]) => toClient.add(ResultFrame(f.id!, d).encode());
        void err(String c) => toClient.add(ErrorFrame(f.id, c, c).encode());
        switch (f.method) {
          case 'hello':
            if (f.params['token'] == this.token) {
              authed = true;
              ok({'authenticated': true});
            } else {
              err('auth_required');
            }
          case 'pair.request':
            ok({'pending': true});
          case 'pair.confirm':
            if (f.params['code'] == code) {
              authed = true;
              ok({'token': this.token});
            } else {
              err('bad_code');
            }
          default:
            if (!authed) return err('auth_required');
            switch (f.method) {
              case 'apps.list':
                ok({
                  'apps': [
                    const CompanionApp(package: 'com.netflix.ninja', label: 'Netflix').toJson(),
                    const CompanionApp(package: 'com.plexapp.android', label: 'Plex').toJson(),
                  ],
                });
              case 'launcher.get':
                ok({'layout': layout.toJson()});
              case 'launcher.set':
                layout = LauncherLayout.fromJson((f.params['layout'] as Map).cast<String, dynamic>());
                ok({'layout': layout.toJson()});
              case 'nowPlaying.get':
                ok({
                  'nowPlaying': const NowPlaying(
                    package: 'com.netflix.ninja',
                    title: 'Serie',
                    state: PlaybackState.playing,
                    positionMs: 10,
                    durationMs: 100,
                  ).toJson(),
                });
              case 'apps.icon':
                ok({'package': f.params['package'], 'png': onePixelPng});
              case 'usage.get':
                ok({
                  'since': 0,
                  'entries': [
                    const UsageEntry(package: 'com.plexapp.android', label: 'Plex', foregroundMs: 45 * 60000).toJson(),
                    const UsageEntry(package: 'com.idle', label: 'Idle', foregroundMs: 0).toJson(),
                    const UsageEntry(package: 'com.netflix.ninja', label: 'Netflix', foregroundMs: 125 * 60000).toJson(),
                  ],
                });
              case 'apps.launch':
                launched.add(f.params['package'] as String);
                ok();
              default:
                err('unsupported');
            }
        }
      });
      return _Chan(toClient.stream, toServer);
    });
  }
}

class _Chan implements CompanionChannel {
  _Chan(this.incoming, this._out);
  @override
  final Stream<String> incoming;
  final StreamController<String> _out;

  @override
  void send(String text) => _out.add(text);

  @override
  Future<void> close() async {
    unawaited(_out.close());
  }
}

Future<CompanionClient> noCompanion(String host, String? token) async =>
    throw const CompanionException('disconnected', 'no launcher');

AppServices buildServices({
  required ClientIdentity identity,
  required FakeTvEnv env,
  FakeDiscovery? discovery,
  FakeDictation? dictation,
  CompanionConnector? companion,
  List<SavedTv> saved = const [],
  PairingStarter? startPairing,
  PairedChecker? isPaired,
  List<(String, String)>? wakes,
}) {
  final settings = MemorySettingsStore();
  final devices = DeviceStore(settings: settings, secrets: MemorySecretStore(), identity: identity);
  if (saved.isNotEmpty) {
    settings.values['tvs.v1'] = jsonEncode([for (final t in saved) t.toJson()]);
  }
  return AppServices(
    devices: devices,
    preferences: Preferences(settings),
    discovery: discovery ?? FakeDiscovery(),
    dictation: dictation ?? FakeDictation(),
    sessionFactory: (tv, id, d) => TvSession(
      tv: tv,
      identity: id,
      devices: d,
      clientFactory: env.client,
      companionConnector: companion ?? noCompanion,
      wake: (mac, host) async {
        wakes?.add((mac, host));
        return 3;
      },
      keyInterval: Duration.zero,
    ),
    startPairing: startPairing,
    readTvInfo: (host, id) async => (name: 'Hisense 65U6GA', mac: 'AA:BB:CC:DD:EE:FF'),
    isPaired: isPaired ?? (host, id) async => false,
  );
}
