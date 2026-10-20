import 'dart:io';
import 'dart:typed_data';

/// Builds a Wake-on-LAN magic packet: 6 x 0xFF then the MAC 16 times.
Uint8List magicPacket(String mac) {
  final hex = mac.replaceAll(RegExp(r'[:\-.\s]'), '');
  if (!RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(hex)) {
    throw ArgumentError.value(mac, 'mac', 'expected 6 bytes, e.g. AA:BB:CC:DD:EE:FF');
  }
  final macBytes = [for (var i = 0; i < 12; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];
  return Uint8List.fromList([...List.filled(6, 0xff), for (var i = 0; i < 16; i++) ...macBytes]);
}

/// Sends the magic packet for [mac] to [broadcastAddress] on ports 9 and 7.
///
/// Only wakes TVs whose "Wake on LAN/Wi-Fi" setting is enabled. Returns the
/// number of datagrams the OS accepted; never throws (0 means nothing could
/// be sent, e.g. iOS without the multicast entitlement refuses broadcasts).
Future<int> sendWakeOnLan(
  String mac, {
  String broadcastAddress = '255.255.255.255',
  List<int> ports = const [9, 7],
  int repeat = 3,
}) =>
    sendWakeOnLanTo(mac, [broadcastAddress], ports: ports, repeat: repeat);

/// Like [sendWakeOnLan] for several targets. A unicast target (the TV's own
/// IP) needs no broadcast permission and works while the router or the phone
/// still knows the TV's MAC address.
Future<int> sendWakeOnLanTo(
  String mac,
  List<String> targets, {
  List<int> ports = const [9, 7],
  int repeat = 3,
}) async {
  final packet = magicPacket(mac);
  RawDatagramSocket socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  } on SocketException {
    return 0;
  }
  var sent = 0;
  try {
    try {
      socket.broadcastEnabled = true;
    } on SocketException {
      // Unicast targets still work.
    }
    final addresses = [for (final t in targets) InternetAddress.tryParse(t)].whereType<InternetAddress>().toList();
    for (var r = 0; r < repeat; r++) {
      for (final target in addresses) {
        for (final port in ports) {
          try {
            if (socket.send(packet, target, port) > 0) sent++;
          } on SocketException {
            // e.g. EHOSTUNREACH for broadcasts on iOS; try the next target.
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  } finally {
    socket.close();
  }
  return sent;
}

/// The directed broadcast address of an IPv4 address assuming a /24 network,
/// e.g. 192.168.1.37 -> 192.168.1.255. Some routers drop 255.255.255.255.
String? subnetBroadcastFor(String ipv4) {
  final parts = ipv4.split('.');
  if (parts.length != 4 || parts.any((p) => int.tryParse(p) == null)) return null;
  return '${parts[0]}.${parts[1]}.${parts[2]}.255';
}
