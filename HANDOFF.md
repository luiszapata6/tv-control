# Handoff — 2026-10-20

Para continuar desde Claude Code en la terminal del Mac:

```bash
cd ~/Development
git clone https://github.com/luiszapata6/tv-control.git   # o: cd tv-control && git pull
cd tv-control
claude
```

Primer mensaje sugerido para Claude Code:

> Lee CLAUDE.md y HANDOFF.md. Revisa el último resultado de CI (`git fetch origin ci-results && git show origin/ci-results:latest.md`), arregla lo que falle hasta que todo esté en verde y sigue con "Pendiente" en orden.

Ventaja de la terminal frente a la sesión en la nube: en el Mac hay Flutter, Xcode y la TV en la misma red, así que se puede compilar, correr tests y probar contra la TV real sin esperar a CI.

## Estado

| Fase | Estado |
| --- | --- |
| 0 · Validación contra la TV real | Script listo (`tools/validate/run_phase0.sh`). **Nunca se ha corrido contra la TV.** |
| 1 · `atv_remote` (protocolo) | Hecho; tests + integración con simulador en verde en CI (`c4323b4`), salvo 1 test nuevo, ya corregido localmente (ver abajo) |
| 2 · `companion_protocol` | Hecho, en verde |
| 3 · Launcher (Flutter + Kotlin) | Hecho; APK y tests Kotlin pasan. Las correcciones de la auditoría están en el último commit y **aún no pasan por CI** |
| 4–5 · App iPhone | Hecha; build iOS sin firma pasa en CI. Tests de widgets fallaban por overflows, corregidos en el último commit y **sin verificar** |
| 6 · Widgets / Control Center / Live Activity / Siri | Código escrito (`apps/remote/ios/TVKit`, `ios/TVWidgets`, `Runner/SharedBridge.swift`, `Runner/TVShortcuts.swift`, `lib/src/services/shared_bridge.dart`). **Nunca se ha compilado** |
| 7 · Mac menu-bar | Código escrito (`apps/remote/macos/Runner`). **Nunca se ha compilado** |
| 7 · Automatizaciones, UI de historial de uso, Home Assistant | **Sin empezar** |
| Docs | `docs/INSTALL.md` (guía de instalación en español) |

## Último commit (subido justo antes de este handoff)

Lleva todo lo de las fases 6–7 más las correcciones de la auditoría, sin verificar en CI:

- **atv_remote**
  - Las caídas del handshake TLS ya no obligan a re-emparejar: ahora es `AtvHandshakeException`, y solo 3 seguidas pasan a `needsPairing`.
  - El loop de reconexión sobrevive errores inesperados y la carrera stop/start (contador de generación).
  - El watchdog de inactividad solo se reinicia con tráfico entrante.
  - El cursor IME cuenta code points.
  - WoL: nueva `sendWakeOnLanTo`, unicast primero y nunca lanza excepción.
  - Los streams de estado de `AtvClient` ahora son async (con sync había "Cannot fire new event": este era el test que fallaba).
- **App remote**
  - Conexión companion single-flight.
  - El volumen se re-apunta durante la ventana de asentamiento.
  - El slider se ignora mientras la TV no reporta el volumen.
  - `PowerResult` reemplaza el booleano, con mensajes honestos.
  - Se borra el texto espejo al hacer submit o cambiar de app.
  - La capa de servicios ya no importa widgets (hápticos).
  - Keychain con `first_unlock_this_device`.
  - Se manejan los errores `busy`/`locked` del companion.
  - Fixes de overflow (`Flexible` / `FittedBox`) y `Material` transparente en `Surface`.
- **Launcher** (lo hizo un subagente, sin compilar)
  - `LauncherApps.Callback` reemplaza el receptor de paquetes del manifest.
  - Se reportan los fallos de bind del server y se reintenta.
  - Tokens guardados como hash SHA-256 (todos los iPhones tendrán que re-vincularse).
  - El pairing tiene dueño y devuelve error `busy`; el código se oculta al expirar o al cerrarse la conexión.
  - "Olvidar dispositivos" en ajustes.
  - Límites: 8 conexiones, 64 KB por frame, 30 s para autenticarse.
  - Íconos de máximo 192 px.
  - `@Volatile` en los campos compartidos entre hilos.
  - Arreglado `launcher_test.dart`.
  - **Riesgo:** las firmas de `Draft_6455(List, List, int)` (Java-WebSocket 1.6.0) y de los overrides de `LauncherApps.Callback` se escribieron de memoria. Si Kotlin no compila, empezar por ahí.
- **CI**
  - Build iOS con `tools/ci/build_ios.sh`: `flutter build ios --config-only` y luego `xcodebuild` con la firma desactivada (`flutter build ios --no-codesign` fallaba pidiendo un Development Team).
  - Job de macOS y zip del Mac añadido a la release.

## Pendiente, en orden

1. **Dejar CI en verde con el último commit.** Lo más probable que falle:
   - Compilación Kotlin del launcher (ver el riesgo de arriba).
   - Swift de TVKit / TVWidgets y `add_extension.rb`. Posibles problemas:
     - el orden de "Embed Foundation Extensions" frente a "Thin Binary" (ciclo de build);
     - `#include?` en `TVWidgets.xcconfig`;
     - `if #available` dentro de `WidgetBundle`;
     - `@Parameter(... inclusiveRange:)`.
   - Widget tests de `apps/remote` (`test/app_test.dart`). El test de pairing "Listo, ya controlas tu TV" fallaba sin causa clara; se añadió `visibleTexts()` al mensaje de la aserción para diagnosticarlo.
   - `SpeechListenOptions` en `dictation.dart`: verificar que lo exporte `speech_to_text.dart` 7.x.
2. **Fase 0 contra la TV** (`./tools/validate/run_phase0.sh`). Confirmar:
   - pairing y comandos;
   - si el puerto 6466 sigue vivo en standby (de esto depende encender sin WoL);
   - si `startActivity` desde el servicio funciona con el launcher como home (Android 10+ restringe lanzar actividades desde segundo plano).
3. **Instalar y probar en dispositivos reales**: launcher por ADB (`tools/install/install_launcher.sh IP --make-default`) y la IPA vía SideStore. Revisar:
   - que el App Group resuelva bien con el ID que reescribe SideStore;
   - que funcionen los widgets y Siri.
4. **Fase 7 restante**:
   - Automatizaciones por horario: en el launcher (AlarmManager) o como Atajos de iOS reusando los App Intents, a decidir.
   - UI de historial de uso: ya existe `usage.get` en el protocolo y en Kotlin; falta la pantalla en la app.
   - Integración con Home Assistant: la integración oficial `androidtv_remote` ya habla este protocolo; evaluar si basta con documentarla o exponer el companion.
5. **Auditoría final** con agentes independientes (code review + arquitectura + estrategia de tests) sobre todo el repo, y actualizar el documento del plan:
   - Documento del plan: https://claude.ai/code/artifact/b787e432-2487-4da8-8207-3aded7276ee8
   - Diseño: https://claude.ai/artifact/HuGf1FntKQaaL3DcN1DMB7
6. **Hallazgos de auditoría aún abiertos**, aceptados por ahora:
   - El token del companion viaja en claro por `ws://`; la alternativa es challenge/HMAC o `wss` con pinning.
   - El `FutureBuilder` de íconos recrea el future en cada notify (`control_page.dart`).
   - Faltan tests de: ciclo de vida al volver a primer plano, cambio de TV, banner de re-pairing y dictado.

## Datos útiles

- **Repo:** https://github.com/luiszapata6/tv-control (público).
- **Release:** https://github.com/luiszapata6/tv-control/releases/tag/latest
- **Toolchain de CI:** Flutter stable (3.47.x), Dart 3.13, JDK 21, AGP 9.1, Kotlin 2.4, Gradle 9.3.1.
- **Bundle IDs:**
  - `com.luiszapata.tvcontrol.tvRemote` (iPhone)
  - `com.luiszapata.tvcontrol.tvRemote.TVWidgets` (extensión)
  - `com.luiszapata.tvcontrol.tv_launcher` (TV)
- **Referencia del protocolo:** androidtvremote2 0.3.2 (`pip install androidtvremote2==0.3.2`).
