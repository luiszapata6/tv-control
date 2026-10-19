/// Client for the Android TV Remote v2 protocol.
///
/// * [ClientIdentity] — the self-signed certificate the TV remembers.
/// * [PairingSession] — one-time pairing with the code shown on the TV.
/// * [AtvRemote] — a live command connection (keys, text, app links, state).
/// * [AtvClient] — keeps an [AtvRemote] alive with automatic reconnection.
library;

export 'src/apps.dart';
export 'src/client.dart';
export 'src/crypto/certificate.dart';
export 'src/errors.dart';
export 'src/framing.dart';
export 'src/keys.dart';
export 'src/pairing.dart';
export 'src/pairing_secret.dart';
export 'src/proto/remotemessage.pb.dart' show RemoteKeyCode, RemoteDirection;
export 'src/remote.dart';
export 'src/state.dart';
export 'src/transport.dart';
export 'src/tv_subject.dart';
export 'src/wol.dart';
