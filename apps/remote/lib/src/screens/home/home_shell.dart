import 'package:flutter/material.dart';

import '../../services/services.dart';
import '../../services/tv_session.dart';
import '../../theme/tokens.dart';
import '../../widgets/toast.dart';
import 'apps_page.dart';
import 'control_page.dart';
import 'header.dart';
import 'keyboard_page.dart';
import 'settings_sheet.dart';
import 'touchpad_page.dart';

/// Header + four pages + floating dock.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final TvSession session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _titles = ['Sala', 'Touchpad', 'Apps de la TV', 'Escribir en la TV'];

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final services = Services.of(context);
    return ToastHost(
      child: Scaffold(
        body: ListenableBuilder(
          listenable: s,
          builder: (context, _) {
            final pages = [
              ControlPage(session: s),
              TouchpadPage(session: s),
              AppsPage(session: s),
              KeyboardPage(session: s, dictation: services.dictation),
            ];
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 8),
                        child: SessionHeader(
                          session: s,
                          title: _tab == 0 ? s.tv.name : _titles[_tab],
                          onOpenSettings: () => showSettingsSheet(context, s),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Motion.press,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(anim), child: child),
                          ),
                          child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: Space.gutter,
                  right: Space.gutter,
                  bottom: 12 + MediaQuery.paddingOf(context).bottom,
                  child: Dock(index: _tab, onChanged: (i) => setState(() => _tab = i)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
