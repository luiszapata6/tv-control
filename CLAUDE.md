# TV Control — guía para Claude Code

Proyecto personal de Luis: control para iPhone/Mac y launcher ligero para su TV Hisense 65U6GA (Android TV). Responde en español, conciso y directo; no inventes datos — verifica antes de afirmar.

## Mapa del repo

| Ruta | Qué es | Stack |
| --- | --- | --- |
| `packages/atv_remote` | Cliente del protocolo Android TV Remote v2 (pairing 6467 polo.proto, comandos 6466 remotemessage.proto, TLS con cert propio) | Dart puro |
| `packages/companion_protocol` | Protocolo iPhone ↔ launcher (WebSocket `ws://tv:7790/v1`, JSON). Spec: `PROTOCOL.md`, fixtures: `fixtures/messages.json` | Dart puro |
| `apps/launcher/android` | Launcher de la TV, Android nativo (Views, sin Flutter: la GPU de la Hisense no daba 60 fps con Flutter). UI en `ui/` (diseño 960×540 dp), lógica pura en `core/Home.kt`, servicio del companion protocol en `companion/` | Kotlin |
| `apps/remote` | App iPhone (y macOS como app de barra de menú). `ios/TVKit` = cliente Swift nativo para widgets/Siri; `ios/TVWidgets` = extensión (widget, Live Activity, Control Center) | Flutter + Swift |
| `tools/sim` | Simulador Python de la TV (validado contra androidtvremote2 0.3.2) | Python |
| `tools/codegen` | Genera los `.pb.dart` y vectores golden desde androidtvremote2 | Python |
| `tools/validate` | Fase 0 contra la TV real (`run_phase0.sh [IP]`) | Python |
| `tools/install` | Instalar launcher por ADB / restaurar launcher de fábrica | bash |
| `tools/ios/add_extension.rb` | Agrega TVKit + TVWidgets al Xcode project (idempotente, gem xcodeproj) | Ruby |
| `tools/ci` | Pasos de CI y reporte | bash/Python |

## Comandos

```bash
# Dart packages
(cd packages/atv_remote && dart pub get && dart analyze --fatal-infos && dart test)          # integración con simulador: ATV_SIM_PYTHON=$(which python3)
(cd packages/companion_protocol && dart pub get && dart analyze --fatal-infos && dart test)
# Simulador
pip install -r tools/sim/requirements.txt && (cd tools/sim && python -m pytest -q)
python tools/codegen/gen_dart_proto.py      # debe dejar git diff vacío en lib/src/proto
# Launcher
(cd apps/launcher/android && ./gradlew :app:testDebugUnitTest :app:assembleRelease)   # APK: apps/launcher/build/app/outputs/apk/release/
# App iPhone / Mac
(cd apps/remote && flutter pub get && flutter analyze --fatal-infos && flutter test)
ruby tools/ios/add_extension.rb && tools/ci/build_ios.sh     # IPA sin firmar (macOS)
(cd apps/remote && flutter build macos --release)
```

`flutter analyze --fatal-infos` es obligatorio (CI falla con infos).

## CI

`.github/workflows/ci.yml` en cada push a `main`: jobs python, dart, launcher, remote, ios (macos-latest, también build de Mac), release (rolling `latest` con APK, IPA y zip de Mac, solo si todo pasa) y report. Los resultados quedan en la rama `ci-results` (`latest.md`, `runs/<sha12>/summary.md` + logs por paso). Leer: `git fetch origin ci-results && git show origin/ci-results:latest.md`. El job ios hace commit del `Runner.xcodeproj` generado por `add_extension.rb` si cambió.

## Decisiones que no hay que reabrir

- Instalación iOS con SideStore (Apple ID gratis): sin entitlement de multicast → Wake-on-LAN solo unicast + reintento; una única extensión (App IDs limitados).
- App Group `group.com.luiszapata.tvcontrol`; SideStore lo renombra a `<group>.<TEAMID>` — `SharedStore.groupIdentifier` lo resuelve en runtime.
- El identity (cert + clave PKCS#1) vive en Keychain para Flutter y se copia al App Group para que TVKit lo importe en su propio keychain.
- Companion: tokens guardados como SHA-256, un solo código de pairing activo (error `busy`), 5 fallos → 60 s bloqueo, TTL 120 s.
- Fuera de alcance (decidido por Luis): Apple Watch, escenas, fondos/temas (solo modo oscuro), perfiles, control parental. Protectores de pantalla = los de Google.
- No usar repos de Wenia ni TruMed.
