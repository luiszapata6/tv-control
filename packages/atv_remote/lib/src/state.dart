/// Feature bits negotiated in remote_configure.
abstract final class AtvFeature {
  static const ping = 1;
  static const key = 2;
  static const ime = 4;
  static const voice = 8;
  static const unknown1 = 16;
  static const power = 32;
  static const volume = 64;
  static const appLink = 512;

  /// What we ask for by default (no voice: the iPhone sends dictated text).
  static const defaults = ping | key | ime | power | volume | appLink;
}

/// What the TV reports about itself.
class AtvDeviceInfo {
  const AtvDeviceInfo({required this.vendor, required this.model, required this.appVersion});
  final String vendor;
  final String model;
  final String appVersion;

  @override
  bool operator ==(Object other) =>
      other is AtvDeviceInfo && other.vendor == vendor && other.model == model && other.appVersion == appVersion;

  @override
  int get hashCode => Object.hash(vendor, model, appVersion);

  @override
  String toString() => '$vendor $model ($appVersion)';
}

/// Volume as reported by the TV.
class AtvVolume {
  const AtvVolume({required this.level, required this.max, required this.muted});
  final int level;
  final int max;
  final bool muted;

  /// Level as a fraction 0..1 (0 when unknown).
  double get fraction => max <= 0 ? 0 : (level / max).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is AtvVolume && other.level == level && other.max == max && other.muted == muted;

  @override
  int get hashCode => Object.hash(level, max, muted);

  @override
  String toString() => 'AtvVolume($level/$max${muted ? ', muted' : ''})';
}

/// Snapshot of the TV state, updated as the TV pushes changes.
class AtvState {
  const AtvState({this.isOn, this.volume, this.currentApp, this.deviceInfo, this.features = 0});

  final bool? isOn;
  final AtvVolume? volume;
  final String? currentApp;
  final AtvDeviceInfo? deviceInfo;

  /// Features both sides agreed on (see [AtvFeature]).
  final int features;

  bool supports(int feature) => features & feature == feature;

  AtvState copyWith({bool? isOn, AtvVolume? volume, String? currentApp, AtvDeviceInfo? deviceInfo, int? features}) =>
      AtvState(
        isOn: isOn ?? this.isOn,
        volume: volume ?? this.volume,
        currentApp: currentApp ?? this.currentApp,
        deviceInfo: deviceInfo ?? this.deviceInfo,
        features: features ?? this.features,
      );

  @override
  bool operator ==(Object other) =>
      other is AtvState &&
      other.isOn == isOn &&
      other.volume == volume &&
      other.currentApp == currentApp &&
      other.deviceInfo == deviceInfo &&
      other.features == features;

  @override
  int get hashCode => Object.hash(isOn, volume, currentApp, deviceInfo, features);

  @override
  String toString() => 'AtvState(on: $isOn, $volume, app: $currentApp, $deviceInfo)';
}
