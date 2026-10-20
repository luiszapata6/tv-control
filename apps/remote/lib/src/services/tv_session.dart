import 'dart:async';
import 'dart:typed_data';

import 'package:atv_remote/atv_remote.dart';
import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/foundation.dart';

import 'devices.dart';

/// Builds the keep-alive client for a TV (replaced by a fake in tests).
typedef AtvClientFactory = AtvClient Function(SavedTv tv, ClientIdentity identity);

/// Opens the companion connection (replaced by a fake in tests).
typedef CompanionConnector = Future<CompanionClient> Function(String host, String? token);

/// Sends a Wake-on-LAN packet (replaced by a fake in tests).
typedef WakeSender = Future<void> Function(String mac, String host);

enum CompanionStatus {
  /// The TV Control launcher is not reachable (not installed, or another launcher).
  unavailable,

  /// The launcher is there but this iPhone has not paired with it yet.
  needsPairing,

  /// The launcher showed a code; waiting for the user to type it.
  pairing,

  connected,
}

/// An app the user can open from the iPhone.
class RemoteApp {
  const RemoteApp({required this.package, required this.label, this.link});
  final String package;
  final String label;

  /// Deep link override (YouTube opens better from its URL).
  final String? link;
}

/// Everything the UI needs for the selected TV: connection, state, commands,
/// and the companion features of the launcher (apps with icons, layout,
/// what is playing).
class TvSession extends ChangeNotifier {
  TvSession({
    required this.tv,
    required ClientIdentity identity,
    required this.devices,
    AtvClientFactory? clientFactory,
    CompanionConnector? companionConnector,
    WakeSender? wake,
    this.keyInterval = const Duration(milliseconds: 45),
    this.companionRetry = const Duration(seconds: 30),
  })  : _client = (clientFactory ?? _defaultClient)(tv, identity),
        _companionConnector = companionConnector ?? _defaultCompanion,
        _wake = wake ?? _defaultWake;

  final SavedTv tv;
  final DeviceStore devices;
  final AtvClient _client;
  final CompanionConnector _companionConnector;
  final WakeSender _wake;
  final Duration keyInterval;
  final Duration companionRetry;

  static AtvClient _defaultClient(SavedTv tv, ClientIdentity identity) => AtvClient(host: tv.host, identity: identity);

  static Future<CompanionClient> _defaultCompanion(String host, String? token) =>
      CompanionClient.connect(host, token: token, clientName: 'iPhone');

  static Future<void> _defaultWake(String mac, String host) async {
    await sendWakeOnLan(mac);
    final directed = subnetBroadcastFor(host);
    if (directed != null) await sendWakeOnLan(mac, broadcastAddress: directed);
  }

  StreamSubscription<AtvConnectionStatus>? _statusSub;
  StreamSubscription<AtvState>? _stateSub;
  StreamSubscription<EventFrame>? _companionSub;
  Timer? _companionTimer;
  bool _disposed = false;

  AtvConnectionStatus status = AtvConnectionStatus.idle;
  AtvState state = const AtvState();

  CompanionClient? _companion;
  CompanionStatus companionStatus = CompanionStatus.unavailable;
  List<CompanionApp> companionApps = const [];
  LauncherLayout? layout;
  NowPlaying? nowPlaying;
  final _icons = <String, Uint8List?>{};

  /// Volume the user is dragging to (shown instead of the TV value meanwhile).
  int? pendingVolume;
  Future<void>? _volumeLoop;

  bool get isConnected => status == AtvConnectionStatus.connected;
  bool get needsPairing => status == AtvConnectionStatus.needsPairing;
  AtvVolume? get volume => state.volume;

  /// What the slider shows.
  int get displayVolume => pendingVolume ?? state.volume?.level ?? 0;
  int get volumeMax => (state.volume?.max ?? 100) <= 0 ? 100 : state.volume!.max;

  Future<void> start() async {
    _statusSub = _client.statusChanges.listen((s) {
      status = s;
      _notify();
      if (s == AtvConnectionStatus.connected && companionStatus == CompanionStatus.unavailable) {
        unawaited(connectCompanion());
      }
    });
    _stateSub = _client.stateChanges.listen((s) {
      state = s;
      _notify();
    });
    _client.start();
    unawaited(connectCompanion());
    _companionTimer = Timer.periodic(companionRetry, (_) {
      if (companionStatus == CompanionStatus.unavailable) unawaited(connectCompanion());
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Retries right away (e.g. the app came back to the foreground).
  void retryNow() {
    _client.retryNow();
    if (companionStatus == CompanionStatus.unavailable) unawaited(connectCompanion());
  }

  // ---------------------------------------------------------------- commands

  /// Presses a key. Returns false when not connected (the UI shows why).
  bool press(AtvKey key) {
    try {
      _client.press(key);
      return true;
    } on AtvException {
      return false;
    }
  }

  /// Long press: start on finger down, end on finger up.
  bool pressLong(AtvKey key, {required bool start}) {
    try {
      _client.press(key, direction: start ? KeyDirection.startLong : KeyDirection.endLong);
      return true;
    } on AtvException {
      return false;
    }
  }

  String _lastText = '';

  /// Mirrors [text] into the focused field on the TV. An empty text deletes
  /// what was typed before.
  bool setText(String text) {
    try {
      if (text.isEmpty) {
        for (var i = 0; i < _lastText.length.clamp(0, 64); i++) {
          _client.sendKey(RemoteKeyCode.KEYCODE_DEL);
        }
      } else {
        _client.sendText(text);
      }
      _lastText = text;
      return true;
    } on AtvException {
      return false;
    }
  }

  /// Presses Enter: submits the search on the TV.
  bool submitText() => press(AtvKey.enter);

  /// Opens an app: through the launcher when available (any installed app),
  /// otherwise with an app link over the remote protocol.
  Future<bool> launch(RemoteApp app) async {
    final c = _companion;
    if (c != null && companionStatus == CompanionStatus.connected && app.link == null) {
      try {
        await c.launch(app.package);
        return true;
      } on CompanionException {
        // Fall back to the remote protocol.
      }
    }
    try {
      _client.launchApp(app.link ?? app.package);
      return true;
    } on AtvException {
      return false;
    }
  }

  /// Moves the TV volume to [target] by pressing volume up/down; only the
  /// latest target counts while keys are still being sent.
  void setVolume(int target) {
    pendingVolume = target.clamp(0, volumeMax);
    _notify();
    _volumeLoop ??= _driveVolume().whenComplete(() => _volumeLoop = null);
  }

  Future<void> _driveVolume() async {
    var assumed = state.volume?.level ?? 0;
    while (!_disposed && pendingVolume != null) {
      final target = pendingVolume!;
      if (assumed == target) break;
      final up = target > assumed;
      if (!press(up ? AtvKey.volumeUp : AtvKey.volumeDown)) break;
      assumed += up ? 1 : -1;
      await Future<void>.delayed(keyInterval);
    }
    // Let the TV report the real level before the slider follows it again.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    pendingVolume = null;
    _notify();
  }

  bool toggleMute() => press(AtvKey.mute);

  /// Power: a key press when connected; Wake-on-LAN when the TV is off/asleep.
  Future<bool> power() async {
    if (isConnected) return press(AtvKey.power);
    final mac = tv.mac;
    if (mac == null) return false;
    await _wake(mac, tv.host);
    _client.retryNow();
    return true;
  }

  // --------------------------------------------------------------- companion

  Future<void> connectCompanion() async {
    if (_disposed) return;
    final token = await devices.companionToken(tv.id);
    try {
      final c = await _companionConnector(tv.host, token);
      if (_disposed) {
        await c.close();
        return;
      }
      await _companion?.close();
      _companion = c;
      companionStatus = c.authenticated ? CompanionStatus.connected : CompanionStatus.needsPairing;
      unawaited(c.done.then((_) {
        if (_companion == c) {
          _companion = null;
          companionStatus = CompanionStatus.unavailable;
          _notify();
        }
      }));
      _companionSub = c.events.listen(_onCompanionEvent);
      if (c.authenticated) await _loadCompanionData();
    } on CompanionException {
      companionStatus = CompanionStatus.unavailable;
    } catch (_) {
      companionStatus = CompanionStatus.unavailable;
    }
    _notify();
  }

  Future<void> _loadCompanionData() async {
    final c = _companion;
    if (c == null) return;
    try {
      final results = await Future.wait([c.listApps(), c.getLayout(), c.nowPlaying()]);
      companionApps = results[0] as List<CompanionApp>;
      layout = results[1] as LauncherLayout;
      nowPlaying = results[2] as NowPlaying?;
    } on CompanionException {
      // Keep what we had.
    }
    _notify();
  }

  void _onCompanionEvent(EventFrame e) {
    switch (e.event) {
      case CompanionEvent.nowPlaying:
        nowPlaying = e.nowPlaying;
      case CompanionEvent.layoutChanged:
        layout = e.layout ?? layout;
      case CompanionEvent.appsChanged:
        _icons.clear();
        unawaited(_loadCompanionData());
      case CompanionEvent.foregroundApp:
        break;
    }
    _notify();
  }

  /// Asks the launcher to show a code on the TV.
  Future<void> requestCompanionPairing() async {
    final c = _companion;
    if (c == null) return;
    await c.requestPairing(clientName: 'iPhone');
    companionStatus = CompanionStatus.pairing;
    _notify();
  }

  /// Sends the code shown by the launcher. Throws [CompanionException] on a bad code.
  Future<void> confirmCompanionPairing(String code) async {
    final c = _companion;
    if (c == null) throw const CompanionException('disconnected', 'the launcher is not reachable');
    final token = await c.confirmPairing(code);
    await devices.setCompanionToken(tv.id, token);
    companionStatus = CompanionStatus.connected;
    _notify();
    await _loadCompanionData();
  }

  Future<Uint8List?> icon(String package) async {
    if (_icons.containsKey(package)) return _icons[package];
    final c = _companion;
    if (c == null || companionStatus != CompanionStatus.connected) return null;
    try {
      return _icons[package] = await c.icon(package);
    } on CompanionException {
      return _icons[package] = null;
    }
  }

  Uint8List? cachedIcon(String package) => _icons[package];

  /// Apps to show: the TV's real list via the launcher, else well-known apps.
  List<RemoteApp> get apps {
    if (companionStatus == CompanionStatus.connected && companionApps.isNotEmpty) {
      final hidden = layout?.hidden.toSet() ?? const <String>{};
      return [
        for (final a in companionApps)
          if (!hidden.contains(a.package)) RemoteApp(package: a.package, label: a.label),
      ];
    }
    return [
      for (final k in knownApps)
        if (k.package != 'com.android.vending') RemoteApp(package: k.package, label: k.name, link: k.link),
    ];
  }

  /// Apps pinned on the launcher home, in order (favourites on the iPhone too).
  List<RemoteApp> get pinnedApps {
    final order = layout?.order ?? const <String>[];
    final all = {for (final a in apps) a.package: a};
    if (order.isEmpty) return apps.take(4).toList();
    return [
      for (final p in order)
        if (all[p] case final app?) app,
    ];
  }

  Future<void> saveLayout(LauncherLayout next) async {
    final c = _companion;
    if (c == null) return;
    layout = next;
    _notify();
    try {
      layout = await c.setLayout(next);
    } on CompanionException {
      // The next layoutChanged event or reload corrects it.
    }
    _notify();
  }

  Future<void> pin(String package) => saveLayout((layout ?? const LauncherLayout()).pin(package));
  Future<void> unpin(String package) => saveLayout((layout ?? const LauncherLayout()).unpin(package));
  Future<void> reorder(int from, int to) => saveLayout((layout ?? const LauncherLayout()).move(from, to));

  String get currentAppLabel {
    final pkg = nowPlaying?.package ?? state.currentApp;
    if (pkg == null) return '';
    for (final a in companionApps) {
      if (a.package == pkg) return a.label;
    }
    return appLabelFor(pkg);
  }

  @override
  void dispose() {
    _disposed = true;
    _statusSub?.cancel();
    _stateSub?.cancel();
    _companionSub?.cancel();
    _companionTimer?.cancel();
    unawaited(_client.dispose());
    unawaited(_companion?.close());
    super.dispose();
  }
}
