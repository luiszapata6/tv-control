import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/widgets.dart';

import 'devices.dart';
import 'dictation.dart';
import 'discovery.dart';
import 'tv_session.dart';

/// Opens a pairing session with the TV (faked in tests).
typedef PairingStarter = Future<PairingSession> Function(String host, ClientIdentity identity);

/// Reads the TV certificate name/MAC (faked in tests).
typedef TvInfoReader = Future<({String? name, String? mac})> Function(String host, ClientIdentity identity);

/// Checks whether the TV already accepts this iPhone (faked in tests).
typedef PairedChecker = Future<bool> Function(String host, ClientIdentity identity);

/// Everything screens need, injectable for tests.
class AppServices {
  AppServices({
    required this.devices,
    required this.preferences,
    required this.discovery,
    required this.dictation,
    TvSession Function(SavedTv tv, ClientIdentity identity, DeviceStore devices)? sessionFactory,
    PairingStarter? startPairing,
    TvInfoReader? readTvInfo,
    PairedChecker? isPaired,
  })  : sessionFactory = sessionFactory ?? ((tv, id, d) => TvSession(tv: tv, identity: id, devices: d)),
        startPairing = startPairing ?? ((host, id) => PairingSession.start(host: host, identity: id, clientName: 'iPhone')),
        readTvInfo = readTvInfo ?? _readInfo,
        isPaired = isPaired ?? _isPaired;

  final DeviceStore devices;
  final Preferences preferences;
  final TvDiscovery discovery;
  final Dictation dictation;
  final TvSession Function(SavedTv tv, ClientIdentity identity, DeviceStore devices) sessionFactory;
  final PairingStarter startPairing;
  final TvInfoReader readTvInfo;
  final PairedChecker isPaired;

  static Future<({String? name, String? mac})> _readInfo(String host, ClientIdentity id) async {
    final r = await fetchTvCertificate(host: host, identity: id);
    return (name: r.subject?.name, mac: r.subject?.mac);
  }

  static Future<bool> _isPaired(String host, ClientIdentity id) async {
    try {
      final remote = await AtvRemote.connect(host: host, identity: id, timeout: const Duration(seconds: 4));
      await remote.close();
      return true;
    } on AtvException {
      return false;
    }
  }
}

class Services extends InheritedWidget {
  const Services({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Services>()!.services;

  @override
  bool updateShouldNotify(Services old) => old.services != services;
}
