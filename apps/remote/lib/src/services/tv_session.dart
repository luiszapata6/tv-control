import 'dart:async';

import 'package:atv_remote/atv_remote.dart';
import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/foundation.dart';

import 'devices.dart';

/// Builds the keep-alive client for a TV (replaced by a fake in tests).
typedef AtvClientFactory = AtvClient Function(SavedTv tv, ClientIdentity identity);

/// Opens the companion connection (replaced by a fake in tests).
typedef CompanionConnector = Future<CompanionClient> Function(String host, String? token);

/// Sends a Wake-on-LAN packet and returns how many datagrams went out
/// (replaced by a fake in tests).
typedef WakeSender = Future<int> Function(String mac, String host);

/// What pressing power did.
enum PowerResult {
  /// The power key reached the TV.
  sent,

  /// The TV was unreachable: a wake packet went out and we keep retrying.
  waking,

  /// The TV is unreachable and could not be woken (no MAC, or the packet
  /// could not be sent).
  unavailable,
}

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

  // Unicast to the TV first: iOS only allows broadcasts with an entitlement
  // free Apple IDs cannot get, so the broadcasts may silently fail.
  static Future<int> _defaultWake(String mac, String host) =>
      sendWakeOnLanTo(mac, [host, ?subnetBroadcastFor(host), '255.255.255.255']);

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

  /// Whether the TV reported its volume yet (the slider waits for it).
  bool get volumeKnown => state.volume != null && state.volume!.max > 0;

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
      if (s != AtvConnectionStatus.connected) _lastText = '';
    });
    _stateSub = _client.stateChanges.listen((s) {
      // A new app in front means a new text field: forget mirrored text.
      if (s.currentApp != state.currentApp) _lastText = '';
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
  bool submitText() {
    _lastText = '';
    return press(AtvKey.enter);
  }

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
  /// Ignored until the TV reported its volume (we could not know how many
  /// steps to send).
  void setVolume(int target) {
    if (!volumeKnown) return;
    pendingVolume = target.clamp(0, volumeMax);
    _notify();
    final r = _retarget;
    if (r != null && !r.isCompleted) r.complete();
    _volumeLoop ??= _driveVolume().whenComplete(() => _volumeLoop = null);
  }

  /// How long the slider keeps the user's value after the last key, so the
  /// TV can report the real level first.
  static const volumeSettle = Duration(milliseconds: 400);
  Timer? _settleTimer;
  Completer<void>? _retarget;

  Future<void> _driveVolume() async {
    var assumed = state.volume?.level ?? 0;
    while (!_disposed) {
      final target = pendingVolume;
      if (target == null) return;
      if (assumed == target) {
        // Wait for the TV's report; a new target in the meantime restarts
        // the loop from where we are.
        final settled = Completer<void>();
        final retarget = _retarget = Completer<void>();
        _settleTimer?.cancel();
        _settleTimer = Timer(volumeSettle, settled.complete);
        await Future.any([settled.future, retarget.future]);
        _retarget = null;
        if (_disposed) return;
        if (pendingVolume == target) {
          pendingVolume = null;
          _notify();
          return;
        }
        _settleTimer?.cancel();
        continue;
      }
      final up = target > assumed;
      if (!press(up ? AtvKey.volumeUp : AtvKey.volumeDown)) {
        pendingVolume = null;
        _notify();
        return;
      }
      assumed += up ? 1 : -1;
      await Future<void>.delayed(keyInterval);
    }
  }

  bool toggleMute() => press(AtvKey.mute);

  /// Power: a key press when connected; when the TV is unreachable, a
  /// Wake-on-LAN packet and an immediate reconnect attempt (many Android TVs
  /// keep the remote service alive in network standby).
  Future<PowerResult> power() async {
    if (isConnected) return press(AtvKey.power) ? PowerResult.sent : PowerResult.unavailable;
    _client.retryNow();
    final mac = tv.mac;
    if (mac == null) return PowerResult.unavailable;
    final sent = await _wake(mac, tv.host);
    return sent > 0 ? PowerResult.waking : PowerResult.unavailable;
  }

  // --------------------------------------------------------------- companion

  Future<void>? _companionConnecting;

  /// Connects to the launcher once at a time; concurrent callers share it.
  Future<void> connectCompanion() =>
      _companionConnecting ??= _connectCompanion().whenComplete(() => _companionConnecting = null);

  Future<void> _connectCompanion() async {
    if (_disposed || _companion != null) return;
    final token = await devices.companionToken(tv.id);
    try {
      final c = await _companionConnector(tv.host, token);
      if (_disposed) {
        await c.close();
        return;
      }
      _companion = c;
      companionStatus = c.authenticated ? CompanionStatus.connected : CompanionStatus.needsPairing;
      unawaited(c.done.then((_) {
        if (_companion == c) {
          _companion = null;
          companionStatus = CompanionStatus.unavailable;
          _notify();
        }
      }));
      await _companionSub?.cancel();
      _companionSub = c.events.listen(_onCompanionEvent);
      if (c.authenticated) await _loadCompanionData();
    } catch (_) {
      if (_companion == null) companionStatus = CompanionStatus.unavailable;
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

  /// Time each app spent in front over the last [days], most used first.
  /// Null without the launcher.
  Future<List<UsageEntry>?> usage({int days = 7}) async {
    final c = _companion;
    if (c == null || companionStatus != CompanionStatus.connected) return null;
    try {
      final r = await c.usage(days: days);
      return [...r.entries.where((e) => e.foregroundMs > 0)]..sort((a, b) => b.foregroundMs.compareTo(a.foregroundMs));
    } on CompanionException {
      return null;
    }
  }

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
        ?all[p],
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
    _settleTimer?.cancel();
    final r = _retarget;
    if (r != null && !r.isCompleted) r.complete();
    unawaited(_client.dispose());
    unawaited(_companion?.close());
    super.dispose();
  }
}
