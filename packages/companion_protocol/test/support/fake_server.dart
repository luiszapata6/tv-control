import 'dart:async';
import 'dart:convert';

import 'package:companion_protocol/companion_protocol.dart';

/// In-memory channel pair.
class MemoryChannel implements CompanionChannel {
  MemoryChannel(this._in, this._out);
  final StreamController<String> _in;
  final StreamController<String> _out;

  @override
  Stream<String> get incoming => _in.stream;

  @override
  void send(String text) {
    if (!_out.isClosed) _out.add(text);
  }

  @override
  Future<void> close() async {
    if (!_out.isClosed) unawaited(_out.close());
    if (!_in.isClosed) unawaited(_in.close());
  }
}

/// A Dart model of the TV-side behaviour described in PROTOCOL.md. The Kotlin
/// server implements the same rules; this keeps the client honest.
class FakeCompanionServer {
  FakeCompanionServer({this.validToken = 'secret-token'});

  final String validToken;
  String pairingCode = '482915';
  int failedCodes = 0;
  bool locked = false;
  final launched = <String>[];
  LauncherLayout layout = const LauncherLayout(order: ['com.google.android.youtube.tv'], columns: 6);
  final _clients = <MemoryChannel>[];
  bool dropNextRequest = false;

  Future<CompanionChannel> connect(Uri uri) async {
    final toClient = StreamController<String>();
    final toServer = StreamController<String>();
    final serverSide = MemoryChannel(toServer, toClient);
    _clients.add(serverSide);
    var authed = false;
    serverSide.incoming.listen((text) {
      final frame = CompanionFrame.decode(text) as RequestFrame;
      if (dropNextRequest) {
        dropNextRequest = false;
        return;
      }
      void ok([Map<String, dynamic> data = const {}]) => serverSide.send(ResultFrame(frame.id!, data).encode());
      void err(String code, String message) => serverSide.send(ErrorFrame(frame.id, code, message).encode());
      if (!authed && !CompanionMethod.public.contains(frame.method)) {
        return err(CompanionErrorCode.authRequired, 'pair first');
      }
      switch (frame.method) {
        case CompanionMethod.hello:
          if (frame.params['token'] == validToken) {
            authed = true;
            ok({'authenticated': true, 'server': const ServerInfo(name: 'Hisense 65U6GA', version: 1, deviceId: 'a1').toJson()});
          } else {
            err(CompanionErrorCode.authRequired, 'pair first');
          }
        case CompanionMethod.pairRequest:
          ok({'pending': true});
        case CompanionMethod.pairConfirm:
          if (locked) return err(CompanionErrorCode.locked, 'try later');
          if (frame.params['code'] == pairingCode) {
            authed = true;
            failedCodes = 0;
            ok({'token': validToken, 'server': const ServerInfo(name: 'Hisense 65U6GA', version: 1, deviceId: 'a1').toJson()});
          } else {
            failedCodes++;
            if (failedCodes >= CompanionProtocol.maxFailedCodes) locked = true;
            err(CompanionErrorCode.badCode, 'wrong code');
          }
        case CompanionMethod.ping:
          ok({'time': 1760000000000});
        case CompanionMethod.appsList:
          ok({
            'apps': [
              const CompanionApp(package: 'com.google.android.youtube.tv', label: 'YouTube', versionCode: 3).toJson(),
              const CompanionApp(package: 'com.netflix.ninja', label: 'Netflix').toJson(),
            ],
          });
        case CompanionMethod.appsIcon:
          ok({'package': frame.params['package'], 'png': base64Encode([0x89, 0x50, 0x4e, 0x47])});
        case CompanionMethod.appsLaunch:
          final pkg = frame.params['package'] as String;
          if (pkg == 'missing.app') return err(CompanionErrorCode.notFound, 'app not installed');
          launched.add(pkg);
          ok();
          broadcast(EventFrame(CompanionEvent.foregroundApp, {'package': pkg}));
        case CompanionMethod.launcherGet:
          ok({'layout': layout.toJson()});
        case CompanionMethod.launcherSet:
          layout = LauncherLayout.fromJson((frame.params['layout'] as Map).cast<String, dynamic>());
          ok({'layout': layout.toJson()});
          broadcast(EventFrame(CompanionEvent.layoutChanged, {'layout': layout.toJson()}));
        case CompanionMethod.inputsList:
          ok({
            'inputs': [const TvInput(id: 'hdmi1', label: 'HDMI 1', kind: InputKind.hdmi).toJson()],
          });
        case CompanionMethod.inputsOpen:
          ok();
        case CompanionMethod.nowPlayingGet:
          ok({'nowPlaying': null});
        case CompanionMethod.usageGet:
          ok({
            'since': 0,
            'entries': [const UsageEntry(package: 'com.netflix.ninja', label: 'Netflix', foregroundMs: 3600000).toJson()],
          });
        case CompanionMethod.backupExport:
          ok({'backup': LauncherBackup(layout: layout, exportedAt: DateTime.utc(2026)).toJson()});
        case CompanionMethod.backupImport:
          layout = LauncherBackup.fromJson((frame.params['backup'] as Map).cast<String, dynamic>()).layout;
          ok({'layout': layout.toJson()});
        default:
          err(CompanionErrorCode.unsupported, frame.method);
      }
    });
    return MemoryChannel(toClient, toServer);
  }

  void broadcast(EventFrame e) {
    for (final c in _clients) {
      c.send(e.encode());
    }
  }

  Future<void> dropAll() async {
    for (final c in _clients) {
      await c.close();
    }
    _clients.clear();
  }
}
