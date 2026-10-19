import 'dart:convert';

/// Constants shared with the Kotlin server.
abstract final class CompanionProtocol {
  static const version = 1;
  static const port = 7790;
  static const path = '/v1';
  static const mdnsType = '_tvcontrol._tcp';
  static const maxFailedCodes = 5;
  static const lockSeconds = 60;
}

/// Request and event names.
abstract final class CompanionMethod {
  static const hello = 'hello';
  static const pairRequest = 'pair.request';
  static const pairConfirm = 'pair.confirm';
  static const ping = 'ping';
  static const appsList = 'apps.list';
  static const appsIcon = 'apps.icon';
  static const appsLaunch = 'apps.launch';
  static const launcherGet = 'launcher.get';
  static const launcherSet = 'launcher.set';
  static const inputsList = 'inputs.list';
  static const inputsOpen = 'inputs.open';
  static const nowPlayingGet = 'nowPlaying.get';
  static const usageGet = 'usage.get';
  static const backupExport = 'backup.export';
  static const backupImport = 'backup.import';

  /// Methods allowed before authentication.
  static const public = {hello, pairRequest, pairConfirm, ping};
}

abstract final class CompanionEvent {
  static const nowPlaying = 'nowPlaying';
  static const foregroundApp = 'foregroundApp';
  static const layoutChanged = 'layoutChanged';
  static const appsChanged = 'appsChanged';
}

abstract final class CompanionErrorCode {
  static const authRequired = 'auth_required';
  static const badCode = 'bad_code';
  static const locked = 'locked';
  static const notFound = 'not_found';
  static const badRequest = 'bad_request';
  static const unsupported = 'unsupported';
  static const internal = 'internal';
}

/// One frame on the wire.
sealed class CompanionFrame {
  const CompanionFrame();

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  /// Parses a frame; throws [FormatException] for anything malformed.
  static CompanionFrame decode(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      rethrow;
    }
    if (raw is! Map) throw const FormatException('frame must be a JSON object');
    final j = raw.cast<String, dynamic>();
    final type = j['type'];
    if (type is! String || type.isEmpty) throw const FormatException('frame without type');
    final id = j['id'];
    if (id != null && id is! int) throw const FormatException('id must be an integer');
    switch (type) {
      case 'result':
        if (id == null) throw const FormatException('result without id');
        final data = j['data'];
        return ResultFrame(id as int, data == null ? const {} : (data as Map).cast<String, dynamic>());
      case 'error':
        return ErrorFrame(id as int?, j['code'] as String? ?? CompanionErrorCode.internal, j['message'] as String? ?? '');
      case 'event':
        final data = j['data'];
        return EventFrame(j['event'] as String, data == null ? const {} : (data as Map).cast<String, dynamic>());
      default:
        final params = Map<String, dynamic>.of(j)
          ..remove('type')
          ..remove('id');
        return RequestFrame(id as int?, type, params);
    }
  }
}

class RequestFrame extends CompanionFrame {
  const RequestFrame(this.id, this.method, [this.params = const {}]);
  final int? id;
  final String method;
  final Map<String, dynamic> params;

  @override
  Map<String, dynamic> toJson() => {if (id != null) 'id': id, 'type': method, ...params};
}

class ResultFrame extends CompanionFrame {
  const ResultFrame(this.id, [this.data = const {}]);
  final int id;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': 'result', 'data': data};
}

class ErrorFrame extends CompanionFrame {
  const ErrorFrame(this.id, this.code, this.message);
  final int? id;
  final String code;
  final String message;

  @override
  Map<String, dynamic> toJson() => {if (id != null) 'id': id, 'type': 'error', 'code': code, 'message': message};
}

class EventFrame extends CompanionFrame {
  const EventFrame(this.event, [this.data = const {}]);
  final String event;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() => {'type': 'event', 'event': event, 'data': data};
}
