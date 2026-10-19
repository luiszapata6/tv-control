import 'proto/remotemessage.pb.dart';

/// The buttons the app exposes, mapped to Android key codes.
enum AtvKey {
  up(RemoteKeyCode.KEYCODE_DPAD_UP),
  down(RemoteKeyCode.KEYCODE_DPAD_DOWN),
  left(RemoteKeyCode.KEYCODE_DPAD_LEFT),
  right(RemoteKeyCode.KEYCODE_DPAD_RIGHT),
  center(RemoteKeyCode.KEYCODE_DPAD_CENTER),
  back(RemoteKeyCode.KEYCODE_BACK),
  home(RemoteKeyCode.KEYCODE_HOME),
  menu(RemoteKeyCode.KEYCODE_MENU),
  volumeUp(RemoteKeyCode.KEYCODE_VOLUME_UP),
  volumeDown(RemoteKeyCode.KEYCODE_VOLUME_DOWN),
  mute(RemoteKeyCode.KEYCODE_VOLUME_MUTE),
  power(RemoteKeyCode.KEYCODE_POWER),
  sleep(RemoteKeyCode.KEYCODE_SLEEP),
  wakeUp(RemoteKeyCode.KEYCODE_WAKEUP),
  playPause(RemoteKeyCode.KEYCODE_MEDIA_PLAY_PAUSE),
  play(RemoteKeyCode.KEYCODE_MEDIA_PLAY),
  pause(RemoteKeyCode.KEYCODE_MEDIA_PAUSE),
  next(RemoteKeyCode.KEYCODE_MEDIA_NEXT),
  previous(RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS),
  rewind(RemoteKeyCode.KEYCODE_MEDIA_REWIND),
  fastForward(RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD),
  search(RemoteKeyCode.KEYCODE_SEARCH),
  assist(RemoteKeyCode.KEYCODE_ASSIST),
  settings(RemoteKeyCode.KEYCODE_SETTINGS),
  input(RemoteKeyCode.KEYCODE_TV_INPUT),
  hdmi1(RemoteKeyCode.KEYCODE_TV_INPUT_HDMI_1),
  hdmi2(RemoteKeyCode.KEYCODE_TV_INPUT_HDMI_2),
  hdmi3(RemoteKeyCode.KEYCODE_TV_INPUT_HDMI_3),
  hdmi4(RemoteKeyCode.KEYCODE_TV_INPUT_HDMI_4),
  channelUp(RemoteKeyCode.KEYCODE_CHANNEL_UP),
  channelDown(RemoteKeyCode.KEYCODE_CHANNEL_DOWN),
  guide(RemoteKeyCode.KEYCODE_GUIDE),
  info(RemoteKeyCode.KEYCODE_INFO),
  captions(RemoteKeyCode.KEYCODE_CAPTIONS),
  appSwitch(RemoteKeyCode.KEYCODE_APP_SWITCH),
  allApps(RemoteKeyCode.KEYCODE_ALL_APPS),
  enter(RemoteKeyCode.KEYCODE_ENTER),
  delete(RemoteKeyCode.KEYCODE_DEL);

  const AtvKey(this.code);
  final RemoteKeyCode code;

  /// Parses `home`, `HOME`, `KEYCODE_HOME` or a numeric key code.
  static RemoteKeyCode? parse(String input) {
    final trimmed = input.trim();
    final number = int.tryParse(trimmed);
    if (number != null) return RemoteKeyCode.valueOf(number);
    for (final k in AtvKey.values) {
      if (k.name.toLowerCase() == trimmed.toLowerCase()) return k.code;
    }
    final upper = trimmed.toUpperCase();
    return RemoteKeyCode.byName(upper.startsWith('KEYCODE_') ? upper : 'KEYCODE_$upper');
  }
}

/// How a key press is delivered. Long presses are START_LONG then END_LONG.
enum KeyDirection {
  short(RemoteDirection.SHORT),
  startLong(RemoteDirection.START_LONG),
  endLong(RemoteDirection.END_LONG);

  const KeyDirection(this.proto);
  final RemoteDirection proto;
}
