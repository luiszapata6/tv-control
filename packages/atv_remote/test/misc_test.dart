import 'package:atv_remote/atv_remote.dart';
import 'package:test/test.dart';

void main() {
  group('keys', () {
    test('parse friendly names, proto names and numbers', () {
      expect(AtvKey.parse('home'), RemoteKeyCode.KEYCODE_HOME);
      expect(AtvKey.parse('VolumeUp'), RemoteKeyCode.KEYCODE_VOLUME_UP);
      expect(AtvKey.parse('DPAD_UP'), RemoteKeyCode.KEYCODE_DPAD_UP);
      expect(AtvKey.parse('KEYCODE_POWER'), RemoteKeyCode.KEYCODE_POWER);
      expect(AtvKey.parse('26'), RemoteKeyCode.KEYCODE_POWER);
      expect(AtvKey.parse('nope'), isNull);
    });
    test('every key maps to a known code', () {
      for (final k in AtvKey.values) {
        expect(k.code.name, startsWith('KEYCODE_'), reason: k.name);
      }
    });
  });

  group('app links', () {
    test('package names become market links', () {
      expect(appLinkFor('com.netflix.ninja'), 'market://launch?id=com.netflix.ninja');
    });
    test('URLs pass through', () {
      expect(appLinkFor('https://www.youtube.com'), 'https://www.youtube.com');
      expect(appLinkFor('market://launch?id=x.y'), 'market://launch?id=x.y');
    });
    test('junk is rejected', () {
      expect(() => appLinkFor(''), throwsArgumentError);
      expect(() => appLinkFor('not a package'), throwsArgumentError);
    });
    test('labels', () {
      expect(appLabelFor('com.netflix.ninja'), 'Netflix');
      expect(appLabelFor('com.google.android.tvlauncher'), 'Inicio');
      expect(appLabelFor('x.y.z'), 'x.y.z');
      for (final a in knownApps) {
        expect(a.launchLink, isNotEmpty);
      }
    });
  });

  group('wake on lan', () {
    test('magic packet layout', () {
      final p = magicPacket('aa:bb:cc:dd:ee:ff');
      expect(p.length, 102);
      expect(p.sublist(0, 6), List.filled(6, 0xff));
      expect(p.sublist(6, 12), [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]);
      expect(p.sublist(96, 102), [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]);
      expect(magicPacket('AA-BB-CC-DD-EE-FF'), p);
    });
    test('invalid MAC', () {
      expect(() => magicPacket('12:34'), throwsArgumentError);
    });
    test('subnet broadcast', () {
      expect(subnetBroadcastFor('192.168.1.37'), '192.168.1.255');
      expect(subnetBroadcastFor('nope'), isNull);
    });
    test('sends to loopback without throwing', () async {
      expect(await sendWakeOnLan('AA:BB:CC:DD:EE:FF', broadcastAddress: '127.0.0.1', repeat: 1), 2);
    });
  });

  group('state', () {
    test('volume fraction', () {
      expect(const AtvVolume(level: 25, max: 100, muted: false).fraction, 0.25);
      expect(const AtvVolume(level: 5, max: 0, muted: false).fraction, 0);
    });
    test('copyWith keeps other fields', () {
      const s = AtvState(isOn: true, currentApp: 'a');
      expect(s.copyWith(currentApp: 'b').isOn, isTrue);
      expect(s.copyWith(isOn: false).currentApp, 'a');
    });
  });
}
