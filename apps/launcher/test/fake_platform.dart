import 'dart:async';
import 'dart:typed_data';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:tv_launcher/src/platform.dart';

class FakeLauncherPlatform implements LauncherPlatform {
  FakeLauncherPlatform({List<LauncherApp>? apps, LauncherLayout? layout, List<TvInput>? inputs})
      : appsList = apps ??
            const [
              LauncherApp(package: 'com.google.android.youtube.tv', label: 'YouTube'),
              LauncherApp(package: 'com.netflix.ninja', label: 'Netflix'),
              LauncherApp(package: 'com.disney.disneyplus', label: 'Disney+'),
              LauncherApp(package: 'com.android.vending', label: 'Google Play Store', isSystem: true),
            ],
        current = layout ?? const LauncherLayout(order: ['com.netflix.ninja', 'com.google.android.youtube.tv']),
        inputList = inputs ?? const [TvInput(id: 'hdmi1', label: 'HDMI 1', kind: InputKind.hdmi)];

  List<LauncherApp> appsList;
  LauncherLayout current;
  List<TvInput> inputList;
  final launched = <String>[];
  final openedInputs = <String>[];
  final controller = StreamController<LauncherEvent>.broadcast();
  int settingsOpened = 0;

  @override
  Future<List<LauncherApp>> apps() async => appsList;

  @override
  Future<Uint8List?> icon(String package) async => null;

  @override
  Future<void> launch(String package) async => launched.add(package);

  @override
  Future<LauncherLayout> layout() async => current;

  @override
  Future<LauncherLayout> setLayout(LauncherLayout layout) async => current = layout;

  @override
  Future<List<TvInput>> inputs() async => inputList;

  @override
  Future<void> openInput(String id) async => openedInputs.add(id);

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Future<void> openAppInfo(String package) async {}

  @override
  Future<String> companionAddress() async => '192.168.1.50:7790';

  @override
  Stream<LauncherEvent> get events => controller.stream;
}
