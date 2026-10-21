import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home/home_shell.dart';
import 'screens/onboarding/discover_screen.dart';
import 'services/devices.dart';
import 'services/services.dart';
import 'services/shared_bridge.dart';
import 'services/tv_session.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'widgets/pressable.dart';

/// Root: loads saved TVs, keeps one [TvSession] for the selected TV and
/// shows onboarding until a TV is paired.
class TvRemoteApp extends StatefulWidget {
  const TvRemoteApp({super.key, required this.services, this.useGoogleFonts = true});
  final AppServices services;
  final bool useGoogleFonts;

  @override
  State<TvRemoteApp> createState() => _TvRemoteAppState();
}

class _TvRemoteAppState extends State<TvRemoteApp> with WidgetsBindingObserver {
  TvSession? _session;
  SavedTv? _sessionTv;
  DateTime? _sessionPairedAt;
  bool _ready = false;
  SharedSync? _sync;

  DeviceStore get _devices => widget.services.devices;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _devices.addListener(_onDevices);
    widget.services.preferences.addListener(_applyPrefs);
    unawaited(_load());
  }

  Future<void> _load() async {
    await Future.wait([_devices.load(), widget.services.preferences.load()]);
    await _syncSession();
    if (mounted) setState(() => _ready = true);
  }

  void _applyPrefs() {
    hapticsEnabled = widget.services.preferences.haptics;
    _sync?.refresh();
  }

  void _onDevices() => unawaited(_syncSession().catchError((Object _) {
        // Identity generation failed (keychain unavailable): stay on the splash
        // and try again on the next change.
      }));

  Future<void> _syncSession() async {
    final tv = _devices.selected;
    final changed = tv?.id != _sessionTv?.id || tv?.host != _sessionTv?.host || tv?.pairedAt != _sessionPairedAt;
    if (!changed) return;
    final old = _session;
    _session = null;
    _sync?.dispose();
    _sync = null;
    _sessionTv = tv;
    _sessionPairedAt = tv?.pairedAt;
    old?.dispose();
    if (tv != null) {
      final identity = await _devices.identity();
      if (!mounted || _sessionTv?.id != tv.id) return;
      final s = widget.services.sessionFactory(tv, identity, _devices);
      _session = s;
      _sync = SharedSync(widget.services.shared, s, identity, liveActivity: widget.services.preferences.liveActivity);
      await s.start();
    } else {
      unawaited(widget.services.shared.clearTv());
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _session?.retryNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _devices.removeListener(_onDevices);
    widget.services.preferences.removeListener(_applyPrefs);
    _sync?.dispose();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.services.preferences;
    return Services(
      services: widget.services,
      child: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => AccentScope(
          accent: Accent.byName(prefs.accentName),
          child: MaterialApp(
            title: 'TV Control',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(useGoogleFonts: widget.useGoogleFonts),
            home: ListenableBuilder(
              listenable: _devices,
              builder: (context, _) {
                if (!_ready) return const _Splash();
                if (_devices.tvs.isEmpty) return const DiscoverScreen();
                final s = _session;
                if (s == null) return const _Splash();
                return HomeShell(key: ObjectKey(s), session: s);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.4))),
      );
}
