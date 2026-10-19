/// Converts a package name or URL into the app link the TV understands.
///
/// URLs (anything with a scheme) are sent as-is and open the app registered
/// for them; a bare package name becomes `market://launch?id=<package>`,
/// which launches any installed app.
String appLinkFor(String packageOrUrl) {
  final value = packageOrUrl.trim();
  if (value.isEmpty) throw ArgumentError.value(packageOrUrl, 'packageOrUrl', 'empty');
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$').hasMatch(value)) {
    throw ArgumentError.value(packageOrUrl, 'packageOrUrl', 'not a package name or URL');
  }
  return 'market://launch?id=$value';
}

/// Well-known TV apps: friendly name and package.
class KnownApp {
  const KnownApp(this.name, this.package, {this.link});
  final String name;
  final String package;

  /// Optional deep link that opens the app's home screen.
  final String? link;

  String get launchLink => link ?? appLinkFor(package);
}

const knownApps = <KnownApp>[
  KnownApp('YouTube', 'com.google.android.youtube.tv', link: 'https://www.youtube.com'),
  KnownApp('Netflix', 'com.netflix.ninja'),
  KnownApp('Disney+', 'com.disney.disneyplus'),
  KnownApp('Prime Video', 'com.amazon.amazonvideo.livingroom'),
  KnownApp('Max', 'com.wbd.stream'),
  KnownApp('Spotify', 'com.spotify.tv.android'),
  KnownApp('Plex', 'com.plexapp.android'),
  KnownApp('YouTube Music', 'com.google.android.youtube.tvmusic'),
  KnownApp('Apple TV', 'com.apple.atve.androidtv.appletv'),
  KnownApp('Paramount+', 'com.cbs.ott'),
  KnownApp('Crunchyroll', 'com.crunchyroll.crunchyroid'),
  KnownApp('Twitch', 'tv.twitch.android.app'),
  KnownApp('Google Play Store', 'com.android.vending'),
];

/// Looks up a friendly name for [package], falling back to the package itself.
String appLabelFor(String package) {
  for (final app in knownApps) {
    if (app.package == package) return app.name;
  }
  if (package == 'com.google.android.tvlauncher' || package == 'com.google.android.apps.tv.launcherx') {
    return 'Inicio';
  }
  return package;
}
