import 'dart:async';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/foundation.dart';

import 'platform.dart';
import 'weather.dart';

/// State of the launcher UI: apps, layout, inputs, weather and pairing.
class HomeController extends ChangeNotifier {
  HomeController(
    this.platform, {
    WeatherService? weather,
    this.place = WeatherPlace.medellin,
    this.weatherRefresh,
    this.iconRetryAfter = const Duration(minutes: 1),
    DateTime Function()? now,
  })  : _weatherService = weather ?? WeatherService(),
        _now = now ?? DateTime.now;

  final LauncherPlatform platform;
  final WeatherService _weatherService;
  final WeatherPlace place;

  /// How often to refresh the weather; null loads it once (tests).
  final Duration? weatherRefresh;

  /// A failed icon is asked again after this (or on the next appsChanged).
  final Duration iconRetryAfter;
  final DateTime Function() _now;
  StreamSubscription<LauncherEvent>? _sub;
  Timer? _weatherTimer;

  List<LauncherApp> allApps = const [];
  LauncherLayout layout = const LauncherLayout();
  List<TvInput> inputs = const [];
  Weather? weather;
  String? pairingCode;
  String? pairingClient;
  List<String> companionClients = const [];
  bool loading = true;

  /// The last [refresh] failure, null when it worked.
  Object? loadError;
  final _icons = <String, Uint8List>{};
  final _iconFailedAt = <String, DateTime>{};

  /// Pinned apps that are still installed, in the user's order. With no
  /// layout yet, the first launchable non-system apps are suggested.
  List<LauncherApp> get pinned {
    final byPackage = {for (final a in allApps) a.package: a};
    if (layout.order.isEmpty) {
      return allApps.where((a) => !a.isSystem && !layout.hidden.contains(a.package)).take(layout.columns).toList();
    }
    return [
      for (final p in layout.order)
        if (byPackage[p] case final app?) app,
    ];
  }

  /// Everything that is not hidden, alphabetically.
  List<LauncherApp> get visibleApps {
    final list = allApps.where((a) => !layout.hidden.contains(a.package)).toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  List<LauncherApp> get hiddenApps => allApps.where((a) => layout.hidden.contains(a.package)).toList();

  bool isPinned(String package) => layout.order.contains(package) || (layout.order.isEmpty && pinned.any((a) => a.package == package));

  Future<void> start() async {
    _sub = platform.events.listen(_onEvent);
    await refresh();
    unawaited(_loadWeather());
    final every = weatherRefresh;
    if (every != null) _weatherTimer = Timer.periodic(every, (_) => _loadWeather());
  }

  /// Reloads apps, layout and inputs. Never throws: a failure is kept in
  /// [loadError] and the previous data stays on screen.
  Future<void> refresh() async {
    try {
      final results = await Future.wait([platform.apps(), platform.layout(), platform.inputs().catchError((_) => <TvInput>[])]);
      allApps = results[0] as List<LauncherApp>;
      layout = results[1] as LauncherLayout;
      inputs = results[2] as List<TvInput>;
      loadError = null;
    } catch (e) {
      loadError = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadWeather() async {
    final w = await _weatherService.current(place);
    if (w != null) {
      weather = w;
      notifyListeners();
    }
  }

  void _onEvent(LauncherEvent e) {
    switch (e) {
      case AppsChanged():
        _icons.clear();
        _iconFailedAt.clear();
        unawaited(refresh());
      case LayoutChanged(:final layout):
        this.layout = layout;
        notifyListeners();
      case PairingCodeChanged(:final code, :final client):
        pairingCode = code;
        pairingClient = client;
        notifyListeners();
      case CompanionClientsChanged(:final names):
        companionClients = names;
        notifyListeners();
    }
  }

  /// Icon bytes, cached. A missing icon or an error is retried after
  /// [iconRetryAfter] or on the next appsChanged.
  Future<Uint8List?> icon(String package) async {
    final cached = _icons[package];
    if (cached != null) return cached;
    final failedAt = _iconFailedAt[package];
    if (failedAt != null && _now().difference(failedAt) < iconRetryAfter) return null;
    Uint8List? bytes;
    try {
      bytes = await platform.icon(package);
    } catch (_) {
      bytes = null;
    }
    if (bytes != null && bytes.isNotEmpty) {
      _icons[package] = bytes;
      _iconFailedAt.remove(package);
    } else {
      _iconFailedAt[package] = _now();
    }
    return bytes;
  }

  Future<void> launch(LauncherApp app) => platform.launch(app.package);

  /// Shows [next] right away; if saving fails the previous layout comes back.
  /// Returns whether it was saved.
  Future<bool> _save(LauncherLayout next) async {
    final previous = layout;
    layout = next;
    notifyListeners();
    try {
      layout = await platform.setLayout(next);
      return true;
    } catch (_) {
      // Only revert if nothing newer (e.g. a layoutChanged event) replaced it.
      if (identical(layout, next)) layout = previous;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// When the user edits for the first time, the suggested apps become the layout.
  LauncherLayout get _materialized =>
      layout.order.isEmpty ? layout.copyWith(order: pinned.map((a) => a.package).toList()) : layout;

  Future<bool> pin(LauncherApp app) => _save(_materialized.pin(app.package));
  Future<bool> unpin(LauncherApp app) => _save(_materialized.unpin(app.package));
  Future<bool> hide(LauncherApp app) =>
      _save(_materialized.unpin(app.package).copyWith(hidden: {...layout.hidden, app.package}.toList()));
  Future<bool> unhide(LauncherApp app) =>
      _save(layout.copyWith(hidden: [...layout.hidden]..remove(app.package)));
  Future<bool> setColumns(int columns) => _save(_materialized.copyWith(columns: columns));

  /// Moves a pinned app one step left (-1) or right (+1).
  Future<bool> shift(LauncherApp app, int delta) {
    final base = _materialized;
    final from = base.order.indexOf(app.package);
    if (from < 0) return Future.value(false);
    return _save(base.move(from, from + delta));
  }

  Future<void> openInput(TvInput input) => platform.openInput(input.id);

  /// Forgets every paired iPhone (they must pair again) and disconnects them.
  Future<void> revokeDevices() async {
    await platform.revokeDevices();
    companionClients = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }
}
