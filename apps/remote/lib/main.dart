import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/services/devices.dart';
import 'src/services/dictation.dart';
import 'src/services/discovery.dart';
import 'src/services/services.dart';
import 'src/services/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = PrefsSettingsStore();
  final services = AppServices(
    devices: DeviceStore(settings: settings, secrets: const KeychainSecretStore()),
    preferences: Preferences(settings),
    discovery: BonsoirTvDiscovery(),
    dictation: SpeechDictation(),
  );
  runApp(TvRemoteApp(services: services));
}
