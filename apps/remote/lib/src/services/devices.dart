import 'dart:convert';

import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/foundation.dart';

import '../widgets/pressable.dart';
import 'storage.dart';

/// A paired TV.
@immutable
class SavedTv {
  const SavedTv({required this.id, required this.name, required this.host, this.mac, this.pairedAt});

  /// Stable id: the MAC when known, else the host.
  final String id;
  final String name;
  final String host;
  final String? mac;
  final DateTime? pairedAt;

  SavedTv copyWith({String? name, String? host, String? mac}) =>
      SavedTv(id: id, name: name ?? this.name, host: host ?? this.host, mac: mac ?? this.mac, pairedAt: pairedAt);

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'host': host, 'mac': mac, 'pairedAt': pairedAt?.toIso8601String()};

  factory SavedTv.fromJson(Map<String, dynamic> j) => SavedTv(
        id: j['id'] as String,
        name: j['name'] as String,
        host: j['host'] as String,
        mac: j['mac'] as String?,
        pairedAt: j['pairedAt'] == null ? null : DateTime.tryParse(j['pairedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is SavedTv && other.id == id && other.name == name && other.host == host && other.mac == mac;

  @override
  int get hashCode => Object.hash(id, name, host, mac);
}

/// Saved TVs, the selected one, the client identity and companion tokens.
class DeviceStore extends ChangeNotifier {
  DeviceStore({required this.settings, required this.secrets, this.identityBits = 2048, ClientIdentity? identity})
      : _identity = identity;

  final SettingsStore settings;
  final SecretStore secrets;
  final int identityBits;

  static const _tvsKey = 'tvs.v1';
  static const _selectedKey = 'tvs.selected';
  static const _identityKey = 'identity.v1';
  static String _tokenKey(String tvId) => 'companion.token.$tvId';

  List<SavedTv> tvs = const [];
  String? selectedId;
  bool loaded = false;
  ClientIdentity? _identity;
  Future<ClientIdentity>? _identityFuture;

  SavedTv? get selected {
    for (final t in tvs) {
      if (t.id == selectedId) return t;
    }
    return tvs.isEmpty ? null : tvs.first;
  }

  Future<void> load() async {
    final raw = await settings.getString(_tvsKey);
    if (raw != null) {
      try {
        tvs = [for (final j in jsonDecode(raw) as List) SavedTv.fromJson((j as Map).cast<String, dynamic>())];
      } catch (_) {
        tvs = const [];
      }
    }
    selectedId = await settings.getString(_selectedKey);
    loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await settings.setString(_tvsKey, jsonEncode([for (final t in tvs) t.toJson()]));
    final id = selectedId;
    if (id != null) await settings.setString(_selectedKey, id);
  }

  /// Adds or updates [tv] (matched by id) and selects it.
  Future<void> save(SavedTv tv) async {
    tvs = [for (final t in tvs) if (t.id != tv.id) t, tv];
    selectedId = tv.id;
    await _persist();
    notifyListeners();
  }

  Future<void> select(String id) async {
    selectedId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    tvs = [for (final t in tvs) if (t.id != id) t];
    if (selectedId == id) selectedId = tvs.isEmpty ? null : tvs.first.id;
    await secrets.delete(_tokenKey(id));
    if (selectedId == null) await settings.remove(_selectedKey);
    await _persist();
    notifyListeners();
  }

  /// The one client certificate this iPhone presents to every TV. Generated
  /// once (2048-bit RSA in a background isolate) and kept in the Keychain.
  Future<ClientIdentity> identity() {
    final cached = _identity;
    if (cached != null) return Future.value(cached);
    return _identityFuture ??= () async {
      final raw = await secrets.read(_identityKey);
      if (raw != null) {
        try {
          return _identity = ClientIdentity.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
        } catch (_) {
          // Corrupt: generate a new one (TVs will ask to pair again).
        }
      }
      final id = await ClientIdentity.generate(commonName: 'TV Control iPhone', bits: identityBits);
      await secrets.write(_identityKey, jsonEncode(id.toJson()));
      return _identity = id;
    }();
  }

  bool get hasIdentity => _identity != null;

  Future<String?> companionToken(String tvId) => secrets.read(_tokenKey(tvId));
  Future<void> setCompanionToken(String tvId, String token) => secrets.write(_tokenKey(tvId), token);
  Future<void> clearCompanionToken(String tvId) => secrets.delete(_tokenKey(tvId));
}

/// User preferences shown in Settings.
class Preferences extends ChangeNotifier {
  Preferences(this.store);
  final SettingsStore store;

  String accentName = 'Índigo';
  bool haptics = true;

  Future<void> load() async {
    accentName = await store.getString('accent') ?? accentName;
    haptics = (await store.getString('haptics')) != 'off';
    hapticsEnabled = haptics;
    notifyListeners();
  }

  Future<void> setAccent(String name) async {
    accentName = name;
    notifyListeners();
    await store.setString('accent', name);
  }

  Future<void> setHaptics(bool on) async {
    haptics = on;
    hapticsEnabled = on;
    notifyListeners();
    await store.setString('haptics', on ? 'on' : 'off');
  }
}
