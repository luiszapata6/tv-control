import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';
import 'protocol.dart';

/// Error answered by the TV, or a local failure (code `disconnected`/`timeout`).
class CompanionException implements Exception {
  const CompanionException(this.code, this.message);
  final String code;
  final String message;

  bool get needsPairing => code == CompanionErrorCode.authRequired;

  @override
  String toString() => 'CompanionException($code): $message';
}

/// A bidirectional text channel (a WebSocket in production).
abstract class CompanionChannel {
  Stream<String> get incoming;
  void send(String text);
  Future<void> close();
}

class WebSocketCompanionChannel implements CompanionChannel {
  WebSocketCompanionChannel._(this._socket)
      : incoming = _socket.where((e) => e is String).cast<String>().asBroadcastStream();

  final WebSocket _socket;

  @override
  final Stream<String> incoming;

  static Future<WebSocketCompanionChannel> connect(Uri uri, {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await WebSocket.connect(uri.toString()).timeout(timeout);
      socket.pingInterval = const Duration(seconds: 10);
      return WebSocketCompanionChannel._(socket);
    } on TimeoutException {
      throw CompanionException('disconnected', 'no answer from $uri');
    } on SocketException catch (e) {
      throw CompanionException('disconnected', 'could not reach $uri: ${e.message}');
    } on WebSocketException catch (e) {
      throw CompanionException('disconnected', e.message);
    }
  }

  @override
  void send(String text) => _socket.add(text);

  @override
  Future<void> close() => _socket.close();
}

typedef ChannelFactory = Future<CompanionChannel> Function(Uri uri);

/// Client for the launcher's companion service.
class CompanionClient {
  CompanionClient._(this._channel, this.requestTimeout) {
    _sub = _channel.incoming.listen(_onText, onDone: _onDone, onError: (Object _) => _onDone());
  }

  final CompanionChannel _channel;
  final Duration requestTimeout;
  late final StreamSubscription<String> _sub;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<EventFrame>.broadcast(sync: true);
  final _closed = Completer<void>();
  int _nextId = 1;

  ServerInfo? server;
  bool authenticated = false;

  /// Events pushed by the TV (see [CompanionEvent]).
  Stream<EventFrame> get events => _events.stream;

  /// Completes when the connection ends.
  Future<void> get done => _closed.future;
  bool get isClosed => _closed.isCompleted;

  static Uri uriFor(String host, {int port = CompanionProtocol.port}) =>
      Uri(scheme: 'ws', host: host, port: port, path: CompanionProtocol.path);

  /// Connects and says hello. With a valid [token] the client is
  /// [authenticated]; otherwise call [requestPairing] and [confirmPairing].
  static Future<CompanionClient> connect(
    String host, {
    int port = CompanionProtocol.port,
    String? token,
    String clientName = 'TV Control',
    ChannelFactory? channelFactory,
    Duration requestTimeout = const Duration(seconds: 8),
  }) async {
    final uri = uriFor(host, port: port);
    final channel = await (channelFactory ?? WebSocketCompanionChannel.connect)(uri);
    final client = CompanionClient._(channel, requestTimeout);
    try {
      final data = await client._call(CompanionMethod.hello, {
        'client': clientName,
        'version': CompanionProtocol.version,
        if (token != null) 'token': token,
      });
      client.authenticated = data['authenticated'] == true;
      final s = data['server'];
      if (s is Map) client.server = ServerInfo.fromJson(s.cast<String, dynamic>());
    } on CompanionException catch (e) {
      if (!e.needsPairing) {
        await client.close();
        rethrow;
      }
    }
    return client;
  }

  void _onText(String text) {
    final CompanionFrame frame;
    try {
      frame = CompanionFrame.decode(text);
    } on FormatException {
      return;
    }
    switch (frame) {
      case ResultFrame(:final id, :final data):
        _pending.remove(id)?.complete(data);
      case ErrorFrame(:final id, :final code, :final message):
        if (id != null) _pending.remove(id)?.completeError(CompanionException(code, message));
      case EventFrame():
        _events.add(frame);
      case RequestFrame():
        break; // The TV does not send requests.
    }
  }

  void _onDone() {
    for (final c in _pending.values) {
      c.completeError(const CompanionException('disconnected', 'connection closed'));
    }
    _pending.clear();
    if (!_closed.isCompleted) _closed.complete();
    _events.close();
  }

  Future<Map<String, dynamic>> _call(String method, [Map<String, dynamic> params = const {}]) {
    if (isClosed) return Future.error(const CompanionException('disconnected', 'connection closed'));
    final id = _nextId++;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    _channel.send(RequestFrame(id, method, params).encode());
    return c.future.timeout(requestTimeout, onTimeout: () {
      _pending.remove(id);
      throw CompanionException('timeout', '$method took too long');
    });
  }

  /// Asks the TV to show a 6 digit code.
  Future<void> requestPairing({String clientName = 'TV Control'}) =>
      _call(CompanionMethod.pairRequest, {'client': clientName});

  /// Sends the code shown on the TV; returns the token to store.
  Future<String> confirmPairing(String code) async {
    final data = await _call(CompanionMethod.pairConfirm, {'code': code.trim()});
    authenticated = true;
    return data['token'] as String;
  }

  Future<DateTime> ping() async {
    final data = await _call(CompanionMethod.ping);
    return DateTime.fromMillisecondsSinceEpoch((data['time'] as num).toInt());
  }

  Future<List<CompanionApp>> listApps() async {
    final data = await _call(CompanionMethod.appsList);
    return [for (final a in data['apps'] as List) CompanionApp.fromJson((a as Map).cast<String, dynamic>())];
  }

  Future<Uint8List> icon(String package) async {
    final data = await _call(CompanionMethod.appsIcon, {'package': package});
    return base64Decode(data['png'] as String);
  }

  Future<void> launch(String package) => _call(CompanionMethod.appsLaunch, {'package': package});

  Future<LauncherLayout> getLayout() async =>
      LauncherLayout.fromJson((((await _call(CompanionMethod.launcherGet))['layout']) as Map).cast<String, dynamic>());

  Future<LauncherLayout> setLayout(LauncherLayout layout) async => LauncherLayout.fromJson(
        (((await _call(CompanionMethod.launcherSet, {'layout': layout.toJson()}))['layout']) as Map)
            .cast<String, dynamic>(),
      );

  Future<List<TvInput>> listInputs() async {
    final data = await _call(CompanionMethod.inputsList);
    return [for (final i in data['inputs'] as List) TvInput.fromJson((i as Map).cast<String, dynamic>())];
  }

  Future<void> openInput(String inputId) => _call(CompanionMethod.inputsOpen, {'input': inputId});

  Future<NowPlaying?> nowPlaying() async {
    final np = (await _call(CompanionMethod.nowPlayingGet))['nowPlaying'];
    return np == null ? null : NowPlaying.fromJson((np as Map).cast<String, dynamic>());
  }

  Future<UsageReport> usage({int days = 7}) async =>
      UsageReport.fromJson(await _call(CompanionMethod.usageGet, {'days': days.clamp(1, 30)}));

  Future<LauncherBackup> exportBackup() async =>
      LauncherBackup.fromJson((((await _call(CompanionMethod.backupExport))['backup']) as Map).cast<String, dynamic>());

  Future<LauncherLayout> importBackup(LauncherBackup backup) async => LauncherLayout.fromJson(
        (((await _call(CompanionMethod.backupImport, {'backup': backup.toJson()}))['layout']) as Map)
            .cast<String, dynamic>(),
      );

  Future<void> close() async {
    await _sub.cancel();
    await _channel.close();
    _onDone();
  }
}

/// Typed views of [EventFrame]s.
extension CompanionEventData on EventFrame {
  NowPlaying? get nowPlaying {
    final np = data['nowPlaying'];
    return np == null ? null : NowPlaying.fromJson((np as Map).cast<String, dynamic>());
  }

  LauncherLayout? get layout {
    final l = data['layout'];
    return l == null ? null : LauncherLayout.fromJson((l as Map).cast<String, dynamic>());
  }

  String? get package => data['package'] as String?;
}
