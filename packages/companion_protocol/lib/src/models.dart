/// Data types of the companion protocol (see PROTOCOL.md).
library;

Map<String, dynamic> _map(Object? v) => (v as Map).cast<String, dynamic>();
List<String> _strings(Object? v) => v == null ? const [] : (v as List).cast<String>();
int? _int(Object? v) => v == null ? null : (v as num).toInt();

class CompanionApp {
  const CompanionApp({required this.package, required this.label, this.versionCode = 0, this.isSystem = false});

  final String package;
  final String label;
  final int versionCode;
  final bool isSystem;

  factory CompanionApp.fromJson(Map<String, dynamic> j) => CompanionApp(
        package: j['package'] as String,
        label: j['label'] as String? ?? j['package'] as String,
        versionCode: _int(j['versionCode']) ?? 0,
        isSystem: j['isSystem'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'package': package, 'label': label, 'versionCode': versionCode, 'isSystem': isSystem};

  @override
  bool operator ==(Object other) =>
      other is CompanionApp &&
      other.package == package &&
      other.label == label &&
      other.versionCode == versionCode &&
      other.isSystem == isSystem;

  @override
  int get hashCode => Object.hash(package, label, versionCode, isSystem);
}

class LauncherLayout {
  const LauncherLayout({this.order = const [], this.hidden = const [], this.columns = 5});

  /// Pinned apps in display order.
  final List<String> order;

  /// Apps never shown, even in "all apps".
  final List<String> hidden;

  /// Grid columns on the TV, 4..8.
  final int columns;

  static const minColumns = 4;
  static const maxColumns = 8;

  factory LauncherLayout.fromJson(Map<String, dynamic> j) => LauncherLayout(
        order: _strings(j['order']),
        hidden: _strings(j['hidden']),
        columns: (_int(j['columns']) ?? 5).clamp(minColumns, maxColumns),
      );

  Map<String, dynamic> toJson() => {'order': order, 'hidden': hidden, 'columns': columns};

  LauncherLayout copyWith({List<String>? order, List<String>? hidden, int? columns}) => LauncherLayout(
        order: order ?? this.order,
        hidden: hidden ?? this.hidden,
        columns: (columns ?? this.columns).clamp(minColumns, maxColumns),
      );

  /// Pins [package] at the end (or [index]) and un-hides it.
  LauncherLayout pin(String package, {int? index}) {
    final next = [...order]..remove(package);
    next.insert((index ?? next.length).clamp(0, next.length), package);
    return copyWith(order: next, hidden: [...hidden]..remove(package));
  }

  LauncherLayout unpin(String package) => copyWith(order: [...order]..remove(package));

  /// Moves the app at [from] to [to] (indices in [order]).
  LauncherLayout move(int from, int to) {
    if (from < 0 || from >= order.length) return this;
    final next = [...order];
    final item = next.removeAt(from);
    next.insert(to.clamp(0, next.length), item);
    return copyWith(order: next);
  }

  @override
  bool operator ==(Object other) =>
      other is LauncherLayout &&
      _listEq(other.order, order) &&
      _listEq(other.hidden, hidden) &&
      other.columns == columns;

  @override
  int get hashCode => Object.hash(Object.hashAll(order), Object.hashAll(hidden), columns);

  @override
  String toString() => 'LauncherLayout(order: $order, hidden: $hidden, columns: $columns)';
}

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

enum InputKind { hdmi, tuner, other }

class TvInput {
  const TvInput({required this.id, required this.label, this.kind = InputKind.other});
  final String id;
  final String label;
  final InputKind kind;

  factory TvInput.fromJson(Map<String, dynamic> j) => TvInput(
        id: j['id'] as String,
        label: j['label'] as String? ?? j['id'] as String,
        kind: InputKind.values.asNameMap()[j['kind']] ?? InputKind.other,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'kind': kind.name};
}

enum PlaybackState { playing, paused, buffering, stopped }

class NowPlaying {
  const NowPlaying({
    required this.package,
    required this.title,
    required this.state,
    this.subtitle,
    this.positionMs,
    this.durationMs,
  });

  final String package;
  final String title;
  final String? subtitle;
  final PlaybackState state;
  final int? positionMs;
  final int? durationMs;

  /// Progress 0..1, or null when the duration is unknown.
  double? get progress =>
      (positionMs == null || durationMs == null || durationMs! <= 0) ? null : (positionMs! / durationMs!).clamp(0.0, 1.0);

  factory NowPlaying.fromJson(Map<String, dynamic> j) => NowPlaying(
        package: j['package'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        state: PlaybackState.values.asNameMap()[j['state']] ?? PlaybackState.stopped,
        positionMs: _int(j['positionMs']),
        durationMs: _int(j['durationMs']),
      );

  Map<String, dynamic> toJson() => {
        'package': package,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'state': state.name,
        if (positionMs != null) 'positionMs': positionMs,
        if (durationMs != null) 'durationMs': durationMs,
      };
}

class UsageEntry {
  const UsageEntry({required this.package, required this.label, required this.foregroundMs});
  final String package;
  final String label;
  final int foregroundMs;

  Duration get foreground => Duration(milliseconds: foregroundMs);

  factory UsageEntry.fromJson(Map<String, dynamic> j) => UsageEntry(
        package: j['package'] as String,
        label: j['label'] as String? ?? j['package'] as String,
        foregroundMs: _int(j['foregroundMs']) ?? 0,
      );

  Map<String, dynamic> toJson() => {'package': package, 'label': label, 'foregroundMs': foregroundMs};
}

class UsageReport {
  const UsageReport({required this.since, required this.entries});
  final DateTime since;
  final List<UsageEntry> entries;

  factory UsageReport.fromJson(Map<String, dynamic> j) => UsageReport(
        since: DateTime.fromMillisecondsSinceEpoch(_int(j['since']) ?? 0, isUtc: true),
        entries: [for (final e in (j['entries'] as List? ?? const [])) UsageEntry.fromJson(_map(e))],
      );

  Map<String, dynamic> toJson() => {
        'since': since.millisecondsSinceEpoch,
        'entries': [for (final e in entries) e.toJson()],
      };
}

class LauncherBackup {
  const LauncherBackup({required this.layout, required this.exportedAt, this.version = 1});
  final int version;
  final LauncherLayout layout;
  final DateTime exportedAt;

  factory LauncherBackup.fromJson(Map<String, dynamic> j) => LauncherBackup(
        version: _int(j['version']) ?? 1,
        layout: LauncherLayout.fromJson(_map(j['layout'])),
        exportedAt: DateTime.fromMillisecondsSinceEpoch(_int(j['exportedAt']) ?? 0, isUtc: true),
      );

  Map<String, dynamic> toJson() =>
      {'version': version, 'layout': layout.toJson(), 'exportedAt': exportedAt.millisecondsSinceEpoch};
}

class ServerInfo {
  const ServerInfo({required this.name, required this.version, required this.deviceId});
  final String name;
  final int version;
  final String deviceId;

  factory ServerInfo.fromJson(Map<String, dynamic> j) => ServerInfo(
        name: j['name'] as String? ?? 'TV',
        version: _int(j['version']) ?? 1,
        deviceId: j['deviceId'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'version': version, 'deviceId': deviceId};
}
