import 'dart:typed_data';

import 'package:atv_remote/atv_remote.dart';
import 'package:atv_remote/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/src/app.dart';
import 'package:tv_remote/src/services/devices.dart';
import 'package:tv_remote/src/services/discovery.dart';
import 'package:tv_remote/src/services/services.dart';
import 'package:tv_remote/src/widgets/controls.dart';
import 'package:tv_remote/src/widgets/pressable.dart';

import 'support.dart';

/// Every text on screen, for failure messages.
String visibleTexts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? t.textSpan?.toPlainText() ?? '').join(' | ');

void main() {
  late ClientIdentity identity;
  late ClientIdentity tvIdentity;
  setUpAll(() async {
    identity = await ClientIdentity.generate(bits: 512, inIsolate: false);
    tvIdentity = await ClientIdentity.generate(bits: 512, inIsolate: false);
    hapticsEnabled = false;
  });

  const sala = SavedTv(id: 'AA:BB:CC:DD:EE:FF', name: 'Sala', host: '192.168.1.50', mac: 'AA:BB:CC:DD:EE:FF');

  Future<void> pumpApp(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    // Let the fake TV handshake (in-memory streams, real microtasks).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> settle(WidgetTester tester) async {
    // `await sub.cancel()` resumes through a root-zone microtask that fake
    // async never flushes; one real event-loop turn lets it run.
    await tester.runAsync(() async {});
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('first launch shows discovered TVs', (tester) async {
    final env = FakeTvEnv(identity);
    final discovery = FakeDiscovery();
    await pumpApp(tester, TvRemoteApp(services: buildServices(identity: identity, env: env, discovery: discovery), useGoogleFonts: false));
    expect(find.text('Elige tu TV'), findsOneWidget);
    expect(find.text('Buscando tu TV…'), findsOneWidget);
    discovery.controller.add(const [DiscoveredTv(name: 'Hisense 65U6GA', host: '192.168.1.50', port: 6466)]);
    await settle(tester);
    expect(find.text('Hisense 65U6GA'), findsOneWidget);
    expect(find.text('192.168.1.50'), findsOneWidget);
  });

  testWidgets('pairing with the code shown on the TV saves it and opens the remote', (tester) async {
    final env = FakeTvEnv(identity);
    final discovery = FakeDiscovery();
    // The fake TV accepts the code whose nonce is 0000.
    late String code;
    for (var c = 0; c < 256; c++) {
      final candidate = '${c.toRadixString(16).padLeft(2, '0').toUpperCase()}0000';
      try {
        computePairingSecret(client: identity.publicNumbers, server: tvIdentity.publicNumbers, code: candidate);
        code = candidate;
        break;
      } on AtvPairingException {
        continue;
      }
    }
    final pairingConnector = FakeConnector(
      serverCertDer: tvIdentity.certificateDer,
      onConnect: (ch, _) => FakePairingTv(
        ch,
        expectedSecret: () => computePairingSecret(client: identity.publicNumbers, server: tvIdentity.publicNumbers, code: code),
      ),
    );
    final services = buildServices(
      identity: identity,
      env: env,
      discovery: discovery,
      startPairing: (host, id) => PairingSession.start(host: host, identity: id, connector: pairingConnector),
    );
    await pumpApp(tester, TvRemoteApp(services: services, useGoogleFonts: false));
    discovery.controller.add(const [DiscoveredTv(name: 'Hisense 65U6GA', host: '192.168.1.50', port: 6466)]);
    await settle(tester);
    await tester.tap(find.text('Hisense 65U6GA'));
    await settle(tester);
    expect(find.text('Escribe el código que aparece en tu TV'), findsOneWidget);
    expect(find.text('Código de 6 caracteres'), findsOneWidget, reason: 'screen: ${visibleTexts(tester)}');
    await tester.enterText(find.byType(TextField), code);
    await settle(tester);
    expect(find.text('Listo, ya controlas tu TV'), findsOneWidget, reason: 'screen: ${visibleTexts(tester)}');
    expect(services.devices.tvs.single.mac, 'AA:BB:CC:DD:EE:FF');
    await tester.tap(find.text('Ir al control'));
    await settle(tester);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('a mistyped code is caught before sending', (tester) async {
    final env = FakeTvEnv(identity);
    final discovery = FakeDiscovery();
    final services = buildServices(
      identity: identity,
      env: env,
      discovery: discovery,
      startPairing: (host, id) => PairingSession.start(
        host: host,
        identity: id,
        connector: FakeConnector(
          serverCertDer: tvIdentity.certificateDer,
          onConnect: (ch, _) => FakePairingTv(ch, expectedSecret: () => Uint8List(32)),
        ),
      ),
    );
    await pumpApp(tester, TvRemoteApp(services: services, useGoogleFonts: false));
    discovery.controller.add(const [DiscoveredTv(name: 'TV', host: '10.0.0.2', port: 6466)]);
    await settle(tester);
    await tester.tap(find.text('TV'));
    await settle(tester);
    // Find a code whose check byte is wrong.
    var bad = 'FF0000';
    try {
      computePairingSecret(client: identity.publicNumbers, server: tvIdentity.publicNumbers, code: bad);
      bad = 'FE0000';
    } on AtvPairingException {
      // FF0000 is already wrong.
    }
    await tester.enterText(find.byType(TextField), bad);
    await settle(tester);
    expect(find.text('Ese código no coincide. Revísalo en la TV.'), findsOneWidget);
    expect(services.devices.tvs, isEmpty);
  });

  group('remote', () {
    late FakeTvEnv env;

    Future<void> pumpRemote(WidgetTester tester, {FakeDictation? dictation, List<(String, String)>? wakes}) async {
      env = FakeTvEnv(identity);
      await pumpApp(
        tester,
        TvRemoteApp(
          services: buildServices(identity: identity, env: env, saved: const [sala], dictation: dictation, wakes: wakes),
          useGoogleFonts: false,
        ),
      );
    }

    testWidgets('shows the TV and its state', (tester) async {
      await pumpRemote(tester);
      expect(find.text('Sala'), findsOneWidget);
      expect(find.textContaining('Sala · Inicio'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('D-pad, OK and navigation buttons send keys', (tester) async {
      await pumpRemote(tester);
      await tester.tap(find.bySemanticsLabel('Arriba'));
      await tester.tap(find.text('OK'));
      await tester.tap(find.text('Atrás'));
      await tester.ensureVisible(find.text('Inicio').last);
      await tester.pump();
      await tester.tap(find.text('Inicio').last);
      await settle(tester);
      expect(env.keyNames, containsAllInOrder(['KEYCODE_DPAD_UP', 'KEYCODE_DPAD_CENTER', 'KEYCODE_BACK', 'KEYCODE_HOME']));
    });

    testWidgets('holding an arrow repeats it', (tester) async {
      await pumpRemote(tester);
      final g = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Derecha')));
      await tester.pump(const Duration(milliseconds: 1000));
      await g.up();
      await settle(tester);
      expect(env.keyNames.where((k) => k == 'KEYCODE_DPAD_RIGHT').length, greaterThan(3));
    });

    testWidgets('dragging the volume slider sends volume keys', (tester) async {
      await pumpRemote(tester);
      await tester.scrollUntilVisible(find.byType(VolumeSlider), 200, scrollable: find.byType(Scrollable).first);
      await settle(tester);
      final slider = find.byType(VolumeSlider);
      final rect = tester.getRect(slider);
      await tester.dragFrom(rect.centerLeft + const Offset(10, 0), Offset(rect.width * 0.4, 0));
      await settle(tester);
      expect(env.keyNames.where((k) => k == 'KEYCODE_VOLUME_UP'), isNotEmpty);
    });

    testWidgets('dock switches pages: touchpad gestures and keyboard text', (tester) async {
      final dictation = FakeDictation();
      await pumpRemote(tester, dictation: dictation);
      await tester.tap(find.text('Touchpad'));
      await settle(tester);
      final pad = find.bySemanticsLabel(RegExp('Área táctil'));
      await tester.drag(pad, const Offset(120, 0));
      await settle(tester);
      expect(env.keyNames, contains('KEYCODE_DPAD_RIGHT'));

      await tester.tap(find.text('Teclado'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'lofi');
      await settle(tester);
      final text = env.tv.received.where((m) => m.remoteImeBatchEdit != null).last.remoteImeBatchEdit!;
      expect(text.editInfo.single.textFieldStatus!.value, 'lofi');
      await tester.tap(find.text('Buscar en la TV'));
      await settle(tester);
      expect(env.keyNames.last, 'KEYCODE_ENTER');
    });

    testWidgets('apps page opens well-known apps without the launcher', (tester) async {
      await pumpRemote(tester);
      await tester.tap(find.text('Apps'));
      await settle(tester);
      expect(find.text('Instala el launcher TV Control'), findsOneWidget);
      await tester.tap(find.text('YouTube').first);
      await settle(tester);
      final links = env.tv.received.where((m) => m.remoteAppLinkLaunchRequest != null).map((m) => m.remoteAppLinkLaunchRequest!.appLink);
      expect(links, contains('https://www.youtube.com'));
      expect(find.text('Abriendo YouTube en la TV'), findsOneWidget);
    });

    testWidgets('settings sheet lists TVs and changes the accent', (tester) async {
      await pumpRemote(tester);
      await tester.tap(find.bySemanticsLabel('Televisores y ajustes'));
      await settle(tester);
      expect(find.text('Televisores'), findsOneWidget);
      expect(find.text('Agregar otra TV'), findsOneWidget);
      final prefs = Services.of(tester.element(find.text('Televisores'))).preferences;
      await tester.tap(find.text('Ámbar'));
      await settle(tester);
      expect(prefs.accentName, 'Ámbar');
    });
  });
}

