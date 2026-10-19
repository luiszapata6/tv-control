import 'dart:async';
import 'dart:typed_data';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/src/message_channel.dart';
import 'package:atv_remote/src/proto/polo.pb.dart';
import 'package:atv_remote/src/proto/remotemessage.pb.dart';

/// Connector that hands out in-memory sockets and lets a test play the TV.
class FakeConnector implements AtvConnector {
  FakeConnector({this.serverCertDer, this.onConnect});

  final Uint8List? serverCertDer;
  void Function(MessageChannel tv, int port)? onConnect;
  int connects = 0;
  Object? failWith;

  @override
  Future<AtvSocket> connect(
    String host,
    int port,
    ClientIdentity identity, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    connects++;
    final err = failWith;
    if (err != null) throw err;
    final pair = MemorySocketPair(clientCertDer: identity.certificateDer, serverCertDer: serverCertDer);
    onConnect?.call(MessageChannel(pair.server), port);
    return pair.client;
  }
}

/// Scripted remote-port TV.
class FakeRemoteTv {
  FakeRemoteTv(this.channel, {this.features = 622, this.autoStart = true}) {
    _sub = channel.messages.listen(_onMessage);
    send(RemoteMessage(
      remoteConfigure: RemoteConfigure(
        code1: features,
        deviceInfo: RemoteDeviceInfo(model: '65U6GA', vendor: 'Hisense', appVersion: '5.2'),
      ),
    ));
  }

  final MessageChannel channel;
  final int features;
  final bool autoStart;
  final received = <RemoteMessage>[];
  final _received = StreamController<RemoteMessage>.broadcast(sync: true);
  late final StreamSubscription<Uint8List> _sub;

  Stream<RemoteMessage> get messages => _received.stream;

  void send(RemoteMessage m) => channel.send(m.writeToBuffer());

  void _onMessage(Uint8List raw) {
    final m = RemoteMessage.fromBuffer(raw);
    received.add(m);
    _received.add(m);
    if (m.remoteConfigure != null) {
      send(RemoteMessage(remoteSetActive: RemoteSetActive()));
    } else if (m.remoteSetActive != null && autoStart) {
      send(RemoteMessage(remoteStart: RemoteStart(started: true)));
      send(RemoteMessage(remoteSetVolumeLevel: RemoteSetVolumeLevel(volumeLevel: 18, volumeMax: 100)));
      send(RemoteMessage(
        remoteImeKeyInject: RemoteImeKeyInject(appInfo: RemoteAppInfo(appPackage: 'com.google.android.tvlauncher')),
      ));
      send(RemoteMessage(remoteImeBatchEdit: RemoteImeBatchEdit(imeCounter: 5, fieldCounter: 2)));
    }
  }

  Future<RemoteMessage> next(bool Function(RemoteMessage) test) =>
      messages.firstWhere(test).timeout(const Duration(seconds: 3));

  Future<void> close() async {
    await _sub.cancel();
    await channel.close();
  }
}

/// Scripted pairing-port TV that accepts [expectedSecret].
class FakePairingTv {
  FakePairingTv(this.channel, {required this.expectedSecret}) {
    channel.messages.listen(_onMessage);
  }

  final MessageChannel channel;
  final Uint8List Function() expectedSecret;
  final received = <OuterMessage>[];

  void _send(OuterMessage m) {
    m
      ..protocolVersion = 2
      ..status ??= OuterMessage_Status.STATUS_OK;
    channel.send(m.writeToBuffer());
  }

  void _onMessage(Uint8List raw) {
    final m = OuterMessage.fromBuffer(raw);
    received.add(m);
    if (m.pairingRequest != null) {
      _send(OuterMessage(pairingRequestAck: PairingRequestAck(serverName: 'Hisense 65U6GA')));
    } else if (m.options != null) {
      _send(OuterMessage(options: Options(preferredRole: Options_RoleType.ROLE_TYPE_INPUT)));
    } else if (m.configuration != null) {
      _send(OuterMessage(configurationAck: ConfigurationAck()));
    } else if (m.secret != null) {
      final ok = _equal(m.secret!.secret!, expectedSecret());
      _send(ok
          ? OuterMessage(secretAck: SecretAck(secret: m.secret!.secret))
          : OuterMessage(status: OuterMessage_Status.STATUS_BAD_SECRET));
    }
  }

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
