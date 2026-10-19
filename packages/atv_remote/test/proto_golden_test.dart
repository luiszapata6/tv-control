import 'package:atv_remote/src/proto/polo.pb.dart';
import 'package:atv_remote/src/proto/remotemessage.pb.dart';
import 'package:atv_remote/src/proto/wire.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

OuterMessage ok(OuterMessage m) => m
  ..protocolVersion = 2
  ..status = OuterMessage_Status.STATUS_OK;

void main() {
  final polo = goldenSection('polo');
  final remote = goldenSection('remote');

  group('polo (pairing) messages match the reference bytes', () {
    final cases = <String, OuterMessage>{
      'pairing_request': ok(OuterMessage(
        pairingRequest: PairingRequest(clientName: 'TV Control', serviceName: 'atvremote'),
      )),
      'pairing_request_ack': ok(OuterMessage(pairingRequestAck: PairingRequestAck(serverName: 'Hisense 65U6GA'))),
      'options': ok(OuterMessage(
        options: Options(
          preferredRole: Options_RoleType.ROLE_TYPE_INPUT,
          inputEncodings: [
            Options_Encoding(type: Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL, symbolLength: 6),
          ],
        ),
      )),
      'configuration': ok(OuterMessage(
        configuration: Configuration(
          clientRole: Options_RoleType.ROLE_TYPE_INPUT,
          encoding: Options_Encoding(type: Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL, symbolLength: 6),
        ),
      )),
      'configuration_ack': ok(OuterMessage(configurationAck: ConfigurationAck())),
      'secret': ok(OuterMessage(secret: Secret(secret: List.generate(32, (i) => i)))),
      'secret_ack': ok(OuterMessage(secretAck: SecretAck(secret: List.generate(32, (i) => i)))),
      'bad_secret': OuterMessage(protocolVersion: 2, status: OuterMessage_Status.STATUS_BAD_SECRET),
    };
    cases.forEach((name, message) {
      test('encode $name', () => expect(toHex(message.writeToBuffer()), polo[name]));
    });

    test('decode options', () {
      final m = OuterMessage.fromBuffer(hexBytes(polo['options']!));
      expect(m.protocolVersion, 2);
      expect(m.status, OuterMessage_Status.STATUS_OK);
      expect(m.options!.preferredRole, Options_RoleType.ROLE_TYPE_INPUT);
      expect(m.options!.inputEncodings.single.symbolLength, 6);
      expect(m.options!.inputEncodings.single.type, Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL);
    });

    test('decode bad secret status', () {
      final m = OuterMessage.fromBuffer(hexBytes(polo['bad_secret']!));
      expect(m.status, OuterMessage_Status.STATUS_BAD_SECRET);
      expect(m.secretAck, isNull);
    });

    test('empty submessages are present after decoding', () {
      expect(OuterMessage.fromBuffer(hexBytes(polo['configuration_ack']!)).configurationAck, isNotNull);
    });
  });

  group('remote messages match the reference bytes', () {
    final cases = <String, RemoteMessage>{
      'client_configure': RemoteMessage(
        remoteConfigure: RemoteConfigure(
          code1: 622,
          deviceInfo: RemoteDeviceInfo(unknown1: 1, unknown2: '1', packageName: 'atvremote', appVersion: '1.0.0'),
        ),
      ),
      'client_set_active': RemoteMessage(remoteSetActive: RemoteSetActive(active: 622)),
      'key_dpad_up_short': RemoteMessage(
        remoteKeyInject: RemoteKeyInject(keyCode: RemoteKeyCode.KEYCODE_DPAD_UP, direction: RemoteDirection.SHORT),
      ),
      'key_center_start_long': RemoteMessage(
        remoteKeyInject: RemoteKeyInject(
          keyCode: RemoteKeyCode.KEYCODE_DPAD_CENTER,
          direction: RemoteDirection.START_LONG,
        ),
      ),
      'key_power_short': RemoteMessage(
        remoteKeyInject: RemoteKeyInject(keyCode: RemoteKeyCode.KEYCODE_POWER, direction: RemoteDirection.SHORT),
      ),
      'app_link_netflix': RemoteMessage(
        remoteAppLinkLaunchRequest: RemoteAppLinkLaunchRequest(appLink: 'market://launch?id=com.netflix.ninja'),
      ),
      'ime_text_hola_mundo': RemoteMessage(
        remoteImeBatchEdit: RemoteImeBatchEdit(
          imeCounter: 7,
          fieldCounter: 3,
          editInfo: [
            RemoteEditInfo(insert: 1, textFieldStatus: RemoteImeObject(start: 9, end: 9, value: 'hola mundo')),
          ],
        ),
      ),
      'ping_response_42': RemoteMessage(remotePingResponse: RemotePingResponse(val1: 42)),
      'negative_int32': RemoteMessage(remoteImeBatchEdit: RemoteImeBatchEdit(imeCounter: -1)),
      'tv_set_active_empty': RemoteMessage(remoteSetActive: RemoteSetActive()),
      'tv_start_true': RemoteMessage(remoteStart: RemoteStart(started: true)),
      'tv_start_false': RemoteMessage(remoteStart: RemoteStart(started: false)),
    };
    cases.forEach((name, message) {
      test('encode $name', () => expect(toHex(message.writeToBuffer()), remote[name]));
    });

    test('decode TV configure', () {
      final m = RemoteMessage.fromBuffer(hexBytes(remote['tv_configure']!));
      expect(m.remoteConfigure!.code1, 622);
      expect(m.remoteConfigure!.deviceInfo!.vendor, 'Hisense');
      expect(m.remoteConfigure!.deviceInfo!.model, '65U6GA');
      expect(m.remoteConfigure!.deviceInfo!.appVersion, '5.2.473254133');
    });

    test('decode volume', () {
      final v = RemoteMessage.fromBuffer(hexBytes(remote['tv_volume_18_muted']!)).remoteSetVolumeLevel!;
      expect(v.volumeLevel, 18);
      expect(v.volumeMax, 100);
      expect(v.volumeMuted, isTrue);
      expect(v.playerModel, '65U6GA');
    });

    test('decode foreground app', () {
      final m = RemoteMessage.fromBuffer(hexBytes(remote['tv_ime_key_inject_youtube']!));
      expect(m.remoteImeKeyInject!.appInfo!.appPackage, 'com.google.android.youtube.tv');
    });

    test('decode ime counters, ping and power', () {
      final b = RemoteMessage.fromBuffer(hexBytes(remote['tv_ime_batch_edit_counters']!)).remoteImeBatchEdit!;
      expect([b.imeCounter, b.fieldCounter], [12, 4]);
      final p = RemoteMessage.fromBuffer(hexBytes(remote['tv_ping_request']!)).remotePingRequest!;
      expect([p.val1, p.val2], [42, 1]);
      expect(RemoteMessage.fromBuffer(hexBytes(remote['tv_start_true']!)).remoteStart!.started, isTrue);
      final off = RemoteMessage.fromBuffer(hexBytes(remote['tv_start_false']!)).remoteStart!;
      expect(off.started ?? false, isFalse);
    });

    test('decode negative int32 and nested error', () {
      expect(RemoteMessage.fromBuffer(hexBytes(remote['negative_int32']!)).remoteImeBatchEdit!.imeCounter, -1);
      final err = RemoteMessage.fromBuffer(hexBytes(remote['tv_error_nested']!)).remoteError!;
      expect(err.value, isTrue);
      expect(err.message!.remoteKeyInject!.keyCode, RemoteKeyCode.KEYCODE_HOME);
    });

    test('decode text', () {
      final b = RemoteMessage.fromBuffer(hexBytes(remote['ime_text_hola_mundo']!)).remoteImeBatchEdit!;
      expect(b.editInfo.single.textFieldStatus!.value, 'hola mundo');
      expect(b.editInfo.single.insert, 1);
    });
  });

  group('key codes', () {
    final codes = (golden['keycodes'] as Map<String, dynamic>).cast<String, int>();
    test('every reference key code exists with the same value', () {
      for (final e in codes.entries) {
        expect(RemoteKeyCode.byName(e.key)?.value, e.value, reason: e.key);
      }
      expect(RemoteKeyCode.values.length, codes.length);
    });
    test('unknown values survive a round trip', () {
      final m = RemoteMessage(remoteKeyInject: RemoteKeyInject(keyCode: RemoteKeyCode.valueOf(9999)));
      expect(RemoteMessage.fromBuffer(m.writeToBuffer()).remoteKeyInject!.keyCode!.value, 9999);
    });
  });

  group('wire codec robustness', () {
    test('unknown fields are skipped', () {
      // field 99 (varint 5), field 100 (bytes "x"), then remote_start{started:true}
      final w = ProtoWriter()
        ..writeInt32(99, 5)
        ..writeString(100, 'x')
        ..writeMessage(40, (s) => s.writeBool(1, true));
      expect(RemoteMessage.fromBuffer(w.takeBytes()).remoteStart!.started, isTrue);
    });
    test('truncated input throws ProtoDecodeException', () {
      final bytes = hexBytes(remote['tv_configure']!);
      expect(() => RemoteMessage.fromBuffer(bytes.sublist(0, bytes.length - 3)), throwsA(isA<ProtoDecodeException>()));
    });
    test('uint32 rejects negatives', () {
      expect(() => ProtoWriter().writeUint32(1, -1), throwsArgumentError);
    });
  });
}
