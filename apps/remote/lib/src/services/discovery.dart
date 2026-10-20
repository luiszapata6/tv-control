import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

/// A TV found on the network.
class DiscoveredTv {
  const DiscoveredTv({required this.name, required this.host, required this.port});
  final String name;
  final String host;
  final int port;

  @override
  bool operator ==(Object other) => other is DiscoveredTv && other.host == host && other.name == name;

  @override
  int get hashCode => Object.hash(host, name);
}

/// Finds Android TVs (`_androidtvremote2._tcp`). Faked in tests.
abstract class TvDiscovery {
  /// Emits the current list every time it changes. Cancel to stop.
  Stream<List<DiscoveredTv>> watch();
}

class BonsoirTvDiscovery implements TvDiscovery {
  static const type = '_androidtvremote2._tcp';

  @override
  Stream<List<DiscoveredTv>> watch() {
    late StreamController<List<DiscoveredTv>> controller;
    BonsoirDiscovery? discovery;
    StreamSubscription<BonsoirDiscoveryEvent>? sub;
    final found = <String, DiscoveredTv>{};

    void emit() => controller.add(found.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

    void add(BonsoirService s) {
      final host = pickAddress(s.hostAddresses);
      if (host == null) return;
      found[s.name] = DiscoveredTv(name: s.name, host: host, port: s.port);
      emit();
    }

    Future<void> start() async {
      final d = BonsoirDiscovery(type: type);
      discovery = d;
      await d.initialize();
      sub = d.eventStream?.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent():
            d.serviceResolver.resolveService(event.service);
          case BonsoirDiscoveryServiceResolvedEvent():
            add(event.service);
          case BonsoirDiscoveryServiceUpdatedEvent():
            add(event.service);
          case BonsoirDiscoveryServiceLostEvent():
            if (found.remove(event.service.name) != null) emit();
          default:
            break;
        }
      });
      await d.start();
    }

    controller = StreamController<List<DiscoveredTv>>(
      onListen: () => start().catchError((Object e) => controller.addError(e)),
      onCancel: () async {
        await sub?.cancel();
        await discovery?.stop();
      },
    );
    return controller.stream;
  }

  /// Prefers an IPv4 address; skips link-local IPv6.
  static String? pickAddress(List<String> addresses) {
    for (final a in addresses) {
      final ip = InternetAddress.tryParse(a);
      if (ip != null && ip.type == InternetAddressType.IPv4) return a;
    }
    for (final a in addresses) {
      if (!a.toLowerCase().startsWith('fe80')) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }
}
