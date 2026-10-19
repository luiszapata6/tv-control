/// Name and MAC address a TV puts in its certificate subject.
class TvSubject {
  const TvSubject(this.name, this.mac);
  final String name;

  /// MAC in `AA:BB:CC:DD:EE:FF` form, or null if the subject has none.
  final String? mac;
}

final _mac = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$');

/// Parses a TV certificate subject common name, e.g.
/// `atvremote/darcy/darcy/SHIELD Android TV/AA:BB:CC:DD:EE:FF`.
///
/// [dnQualifier] covers devices such as the Nexus Player that put the name
/// in that attribute instead.
TvSubject parseTvSubject(String commonName, {String? dnQualifier}) {
  final parts = commonName.split('/');
  final last = parts.last.trim();
  final mac = _mac.hasMatch(last) ? last.toUpperCase().replaceAll('-', ':') : null;
  String name;
  if (dnQualifier != null && dnQualifier.isNotEmpty) {
    name = dnQualifier.split('/').last;
  } else if (parts.length > 1) {
    name = parts[parts.length - 2];
  } else {
    name = commonName;
  }
  return TvSubject(name.trim(), mac);
}
