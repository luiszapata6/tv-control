import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:atv_remote/atv_remote.dart';

/// Command line client, handy for checking a TV from the computer:
///
///   dart run atv_remote:atv pair 192.168.1.50
///   dart run atv_remote:atv key 192.168.1.50 home down center
///   dart run atv_remote:atv text 192.168.1.50 "hola"
///   dart run atv_remote:atv launch 192.168.1.50 com.netflix.ninja
///   dart run atv_remote:atv status 192.168.1.50
///   dart run atv_remote:atv wol AA:BB:CC:DD:EE:FF
Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('atv', 'Android TV remote from the command line.')
    ..argParser.addOption('identity', help: 'identity JSON (certificate + key)', defaultsTo: _defaultIdentityPath())
    ..argParser.addOption('pairing-port', defaultsTo: '$defaultPairingPort')
    ..argParser.addOption('remote-port', defaultsTo: '$defaultRemotePort')
    ..addCommand(_Pair())
    ..addCommand(_Info())
    ..addCommand(_Key())
    ..addCommand(_Text())
    ..addCommand(_Launch())
    ..addCommand(_Status())
    ..addCommand(_Wol());
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } on AtvException catch (e) {
    stderr.writeln(e);
    exitCode = e is AtvAuthException ? 3 : 1;
  }
}

String _defaultIdentityPath() {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
  return '$home/.config/atv_remote/identity.json';
}

abstract class _Base extends Command<void> {
  String get identityPath => globalResults!['identity'] as String;
  int get pairingPort => int.parse(globalResults!['pairing-port'] as String);
  int get remotePort => int.parse(globalResults!['remote-port'] as String);

  String host() {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('missing <host>', usage);
    return rest.first;
  }

  Future<ClientIdentity> identity() async {
    final file = File(identityPath);
    if (file.existsSync()) {
      return ClientIdentity.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    }
    stdout.writeln('Generating a new client certificate (a few seconds)...');
    final id = await ClientIdentity.generate();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(id.toJson()));
    return id;
  }

  Future<T> withRemote<T>(Future<T> Function(AtvRemote r) body) async {
    final remote = await AtvRemote.connect(host: host(), port: remotePort, identity: await identity());
    try {
      return await body(remote);
    } finally {
      // Give the TV a moment to read what we sent before closing.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await remote.close();
    }
  }
}

class _Pair extends _Base {
  @override
  String get name => 'pair';
  @override
  String get description => 'Pair with a TV: it shows a code, type it here.';

  @override
  Future<void> run() async {
    final session = await PairingSession.start(host: host(), port: pairingPort, identity: await identity());
    stdout.writeln('Pairing with ${session.serverName ?? session.subject?.name ?? host()}.');
    while (true) {
      stdout.write('Code shown on the TV: ');
      final code = stdin.readLineSync() ?? '';
      try {
        await session.finish(code);
        stdout.writeln('Paired. MAC: ${session.subject?.mac ?? 'unknown'}');
        return;
      } on AtvPairingException catch (e) {
        if (!isValidPairingCode(code) || e.message.contains('does not match')) {
          stdout.writeln('That code does not look right, try again.');
          continue;
        }
        rethrow;
      }
    }
  }
}

class _Info extends _Base {
  @override
  String get name => 'info';
  @override
  String get description => 'Show the TV name and MAC from its certificate.';

  @override
  Future<void> run() async {
    final r = await fetchTvCertificate(host: host(), port: pairingPort, identity: await identity());
    stdout.writeln(jsonEncode({'name': r.subject?.name, 'mac': r.subject?.mac, 'cn': r.certificate.subjectCommonName}));
  }
}

class _Key extends _Base {
  _Key() {
    argParser.addFlag('long', help: 'long press');
  }
  @override
  String get name => 'key';
  @override
  String get description => 'Press keys: home, back, up, down, left, right, center, volumeUp, POWER, 26...';

  @override
  Future<void> run() async {
    final names = argResults!.rest.skip(1).toList();
    if (names.isEmpty) throw UsageException('missing keys', usage);
    final codes = names.map((n) => AtvKey.parse(n) ?? (throw UsageException('unknown key $n', usage))).toList();
    final long = argResults!['long'] as bool;
    await withRemote((r) async {
      for (final c in codes) {
        if (long) {
          r.sendKey(c, direction: KeyDirection.startLong);
          await Future<void>.delayed(const Duration(milliseconds: 800));
          r.sendKey(c, direction: KeyDirection.endLong);
        } else {
          r.sendKey(c);
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    });
  }
}

class _Text extends _Base {
  @override
  String get name => 'text';
  @override
  String get description => 'Type text into the focused field on the TV.';

  @override
  Future<void> run() async {
    final text = argResults!.rest.skip(1).join(' ');
    if (text.isEmpty) throw UsageException('missing text', usage);
    await withRemote((r) async => r.sendText(text));
  }
}

class _Launch extends _Base {
  @override
  String get name => 'launch';
  @override
  String get description => 'Open an app by package name or URL.';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) throw UsageException('missing package or URL', usage);
    await withRemote((r) async => r.launchApp(rest[1]));
  }
}

class _Status extends _Base {
  @override
  String get name => 'status';
  @override
  String get description => 'Print power, volume, foreground app and device info as JSON.';

  @override
  Future<void> run() async {
    await withRemote((r) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final s = r.state;
      stdout.writeln(const JsonEncoder.withIndent('  ').convert({
        'on': s.isOn,
        'volume': s.volume == null ? null : {'level': s.volume!.level, 'max': s.volume!.max, 'muted': s.volume!.muted},
        'app': s.currentApp,
        'device': s.deviceInfo?.toString(),
        'features': s.features,
      }));
    });
  }
}

class _Wol extends _Base {
  _Wol() {
    argParser.addOption('broadcast', defaultsTo: '255.255.255.255');
  }
  @override
  String get name => 'wol';
  @override
  String get description => 'Send a Wake-on-LAN packet to a MAC address.';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('missing MAC', usage);
    final sent = await sendWakeOnLan(rest.first, broadcastAddress: argResults!['broadcast'] as String);
    stdout.writeln('sent $sent packets');
  }
}
