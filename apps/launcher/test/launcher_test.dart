import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart' show Icons, Size;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_launcher/main.dart';
import 'package:tv_launcher/src/format.dart';
import 'package:tv_launcher/src/home_controller.dart';
import 'package:tv_launcher/src/platform.dart';
import 'package:tv_launcher/src/weather.dart';

import 'fake_platform.dart';

void main() {
  late FakeLauncherPlatform platform;
  HomeController? controllerRef;

  Future<void> pumpLauncher(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = HomeController(platform, weather: WeatherService(get: (_) async => '{"current":{"temperature_2m":22.4,"weather_code":2,"is_day":1}}'));
    controllerRef = controller;
    await controller.start();
    await tester.pumpWidget(TvLauncher(controller: controller, now: () => DateTime(2026, 10, 18, 21, 5)));
    await tester.pumpAndSettle();
  }

  setUp(() => platform = FakeLauncherPlatform());
  tearDown(() {
    controllerRef?.dispose();
    controllerRef = null;
  });

  testWidgets('home shows clock, weather, pinned apps in order and inputs', (tester) async {
    await pumpLauncher(tester);
    expect(find.text('21:05'), findsOneWidget);
    expect(find.text('Domingo, 18 de octubre'), findsOneWidget);
    expect(find.text('BUENAS NOCHES AMIGUE'), findsOneWidget);
    expect(find.text('22°'), findsOneWidget);
    final netflix = tester.getTopLeft(find.text('Netflix'));
    final youtube = tester.getTopLeft(find.text('YouTube'));
    expect(netflix.dx, lessThan(youtube.dx), reason: 'layout order is respected');
    expect(find.text('Disney+'), findsNothing, reason: 'not pinned');
    expect(find.text('HDMI 1'), findsOneWidget);
  });

  testWidgets('D-pad moves focus and select opens the app', (tester) async {
    await pumpLauncher(tester);
    // First pinned app has focus; move right and press select.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(platform.launched, ['com.google.android.youtube.tv']);
  });

  testWidgets('long press opens options and unpins', (tester) async {
    await pumpLauncher(tester);
    await tester.longPress(find.text('Netflix'));
    await tester.pumpAndSettle();
    expect(find.text('Quitar de inicio'), findsOneWidget);
    await tester.tap(find.text('Quitar de inicio'));
    await tester.pumpAndSettle();
    expect(platform.current.order, ['com.google.android.youtube.tv']);
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('menu key moves an app to the right', (tester) async {
    await pumpLauncher(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover a la derecha'));
    await tester.pumpAndSettle();
    expect(platform.current.order, ['com.google.android.youtube.tv', 'com.netflix.ninja']);
  });

  testWidgets('all apps lists every visible app and can pin one', (tester) async {
    await pumpLauncher(tester);
    await tester.tap(find.text('Todas las apps'));
    await tester.pumpAndSettle();
    expect(find.text('Disney+'), findsOneWidget);
    expect(find.text('Google Play Store'), findsOneWidget);
    await tester.longPress(find.text('Disney+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fijar en inicio'));
    await tester.pumpAndSettle();
    expect(platform.current.order.last, 'com.disney.disneyplus');
  });

  testWidgets('HDMI input opens', (tester) async {
    await pumpLauncher(tester);
    await tester.tap(find.text('HDMI 1'));
    await tester.pump();
    expect(platform.openedInputs, ['hdmi1']);
  });

  testWidgets('pairing code overlay appears and disappears', (tester) async {
    await pumpLauncher(tester);
    platform.controller.add(const PairingCodeChanged('482915', 'iPhone de Luis'));
    await tester.pumpAndSettle();
    expect(find.text('482915'), findsOneWidget);
    expect(find.text('iPhone de Luis quiere conectarse'), findsOneWidget);
    platform.controller.add(const PairingCodeChanged(null, null));
    platform.controller.add(const CompanionClientsChanged(['iPhone de Luis']));
    await tester.pumpAndSettle();
    expect(find.text('482915'), findsNothing);
    expect(find.text('iPhone de Luis conectado'), findsOneWidget);
  });

  testWidgets('layout changes from the iPhone update the grid', (tester) async {
    await pumpLauncher(tester);
    platform.controller.add(const LayoutChanged(LauncherLayout(order: ['com.disney.disneyplus'])));
    await tester.pumpAndSettle();
    expect(find.text('Disney+'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('settings cycles grid columns', (tester) async {
    await pumpLauncher(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Columnas en inicio'), findsOneWidget);
    await tester.tap(find.text('Columnas en inicio'));
    await tester.pumpAndSettle();
    expect(platform.current.columns, 7);
    await tester.tap(find.text('Ajustes del sistema'));
    expect(platform.settingsOpened, 1);
  });

  testWidgets('settings revokes paired devices after a second press', (tester) async {
    await pumpLauncher(tester);
    platform.controller.add(const CompanionClientsChanged(['iPhone de Luis']));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dispositivos vinculados'));
    await tester.pumpAndSettle();
    expect(platform.revoked, 0, reason: 'first press only asks for confirmation');
    expect(find.text('OK otra vez para desvincular todos'), findsOneWidget);
    await tester.tap(find.text('Dispositivos vinculados'));
    await tester.pumpAndSettle();
    expect(platform.revoked, 1);
    expect(controllerRef!.companionClients, isEmpty);
    expect(find.text('Listo · el iPhone debe vincularse de nuevo'), findsOneWidget);
  });

  group('controller', () {
    Future<void> flush() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('failed icons are retried later and after appsChanged, found ones are cached', () async {
      var now = DateTime(2026, 10, 19, 12);
      platform.iconBytes = {'com.netflix.ninja': [1, 2, 3]};
      final controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'), now: () => now);
      controllerRef = controller;
      await controller.start();

      expect(await controller.icon('com.netflix.ninja'), [1, 2, 3]);
      expect(await controller.icon('com.netflix.ninja'), [1, 2, 3]);
      expect(platform.iconCalls, ['com.netflix.ninja'], reason: 'cached');

      platform.failIcons = true;
      expect(await controller.icon('com.disney.disneyplus'), isNull);
      expect(await controller.icon('com.disney.disneyplus'), isNull);
      expect(platform.iconCalls.where((p) => p == 'com.disney.disneyplus'), hasLength(1), reason: 'not hammered');

      platform.failIcons = false;
      platform.iconBytes['com.disney.disneyplus'] = [9];
      now = now.add(const Duration(minutes: 2));
      expect(await controller.icon('com.disney.disneyplus'), [9], reason: 'retried after a while');

      platform.iconBytes.remove('com.google.android.youtube.tv');
      expect(await controller.icon('com.google.android.youtube.tv'), isNull);
      platform.iconBytes['com.google.android.youtube.tv'] = [7];
      platform.controller.add(const AppsChanged());
      await flush();
      expect(await controller.icon('com.google.android.youtube.tv'), [7], reason: 'retried on appsChanged');
    });

    test('refresh errors do not leave the launcher loading', () async {
      platform.appsError = StateError('package manager died');
      final controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'));
      controllerRef = controller;
      await controller.refresh();
      expect(controller.loading, isFalse);
      expect(controller.loadError, isA<StateError>());
      platform.appsError = null;
      await controller.refresh();
      expect(controller.loadError, isNull);
      expect(controller.allApps, hasLength(4));
    });

    test('a layout that fails to save is reverted', () async {
      final controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'));
      controllerRef = controller;
      await controller.refresh();
      final before = controller.layout;
      platform.setLayoutError = StateError('prefs unavailable');
      var notified = 0;
      controller.addListener(() => notified++);
      final disney = controller.allApps.firstWhere((a) => a.package == 'com.disney.disneyplus');
      expect(await controller.pin(disney), isFalse);
      expect(controller.layout, before);
      expect(controller.pinned.map((a) => a.package), isNot(contains('com.disney.disneyplus')));
      expect(notified, 2, reason: 'optimistic update, then the revert');
      platform.setLayoutError = null;
      expect(await controller.pin(disney), isTrue);
      expect(controller.layout.order.last, 'com.disney.disneyplus');
    });

    test('without a layout, non-system apps are suggested and editing materializes them', () async {
      platform = FakeLauncherPlatform(layout: const LauncherLayout());
      final controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'));
      controllerRef = controller;
      await controller.refresh();
      expect(controller.pinned.map((a) => a.label), ['YouTube', 'Netflix', 'Disney+']);
      await controller.hide(controller.pinned.first);
      expect(platform.current.order, ['com.netflix.ninja', 'com.disney.disneyplus']);
      expect(platform.current.hidden, ['com.google.android.youtube.tv']);
      expect(controller.visibleApps.map((a) => a.label), isNot(contains('YouTube')));
    });
  });

  group('formatting and weather', () {
    test('dates in Spanish', () {
      expect(formatDate(DateTime(2026, 1, 5)), 'Lunes, 5 de enero');
      expect(formatTime(DateTime(2026, 1, 5, 9, 3)), '9:03');
      expect(greetingFor(DateTime(2026, 1, 5, 8)), 'BUENOS DÍAS AMIGUE');
      expect(greetingFor(DateTime(2026, 1, 5, 14)), 'BUENAS TARDES AMIGUE');
      expect(greetingFor(DateTime(2026, 1, 5, 11, 59)), 'BUENOS DÍAS AMIGUE');
      expect(greetingFor(DateTime(2026, 1, 5, 12)), 'BUENAS TARDES AMIGUE');
      expect(greetingFor(DateTime(2026, 1, 5, 18, 59)), 'BUENAS TARDES AMIGUE');
      expect(greetingFor(DateTime(2026, 1, 5, 19)), 'BUENAS NOCHES AMIGUE');
    });
    test('open-meteo parsing', () async {
      final w = await WeatherService(get: (_) async => '{"current":{"temperature_2m":17.6,"weather_code":63,"is_day":0}}')
          .current(WeatherPlace.medellin);
      expect(w!.temperatureLabel, '18°');
      expect(w.label, 'Lluvia');
      expect(await WeatherService(get: (_) async => throw Exception('offline')).current(WeatherPlace.medellin), isNull);
      expect(WeatherService.uriFor(WeatherPlace.medellin).host, 'api.open-meteo.com');
    });
  });
}
