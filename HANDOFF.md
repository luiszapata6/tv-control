# Handoff — 2026-10-20 (noche)

Para continuar desde Claude Code en el Mac (`cd ~/Development/tv-control && claude`):

> Lee CLAUDE.md y HANDOFF.md, revisa CI (`git fetch origin ci-results && git show origin/ci-results:latest.md`) y sigue con "Pendiente".

## Estado

| Parte | Estado |
| --- | --- |
| Launcher (TV) | **Nativo Kotlin** (se abandonó Flutter: 60 ms/frame en esta GPU). Instalado y como inicio en la TV real. 5–7 ms/frame, 14 MB RAM, arranque 0.4 s, APK 245 KB |
| Fase 0 | Corrida contra la TV (ver abajo) |
| App iPhone | Compila y pasa tests; ajustada al launcher nuevo (favoritos). **Nunca instalada en un iPhone** |
| Widgets / Siri | Compilan. "Abrir app" no funciona en esta TV (ver Fase 0) |
| App Mac | Compila |

## La TV real (verificado)

- Hisense "HiSmartTV A4", **Android TV 9** (SDK 28), 32 bits (m7322), 1.8 GB RAM, IP 192.168.1.6, MAC `E0:D8:C4:45:07:DD`.
- ADB por red: Depuración por USB + reiniciar. `adb kill-server` si dice "No route to host".
- Backup previo al launcher: `tools/install/backups/192.168.1.6/20261020-212357/` (solo en el Mac). Rollback: `tools/install/restore_stock_launcher.sh 192.168.1.6 --uninstall`.
- **Cada actualización del launcher borra la preferencia de inicio**: instala siempre con `tools/install/install_launcher.sh 192.168.1.6 <apk>` (la vuelve a fijar). Si el launcher se cae al arrancar, Android también la borra y Home abre un selector.
- La tecla Menú del control la intercepta Hisense (menú de imagen/sonido): las opciones de app son "mantener OK".

## Fase 0 (2026-10-20)

| Prueba | Resultado |
| --- | --- |
| Pairing, teclas, volumen (16→17), info, app activa | OK |
| Deep link `https://www.youtube.com` | OK |
| `market://launch?id=…`, `intent:#Intent;…;package=…`, https de Netflix | **La TV los rechaza** → abrir apps solo vía launcher (companion `apps.launch`) |
| Reposo | Red sigue viva (cortes de ~10 s por ahorro de Wi-Fi); **POWER enciende desde reposo** |
| KEYCODE_SLEEP / WAKEUP | **Ignoradas**: los intents de Siri "Apagar/Encender" leen `isOn` y mandan POWER solo si hace falta |
| Texto (IME) | No probado (YouTube pedía elegir perfil) |
| mDNS desde Python | Vacío (permiso de red local de macOS); `dns-sd` sí la ve |

## Pendiente, en orden

1. **Instalar la app en el iPhone** con SideStore (`docs/INSTALL.md`) y probar: pairing con la TV, control, favoritos, vincular el launcher (código numérico de 6 dígitos).
2. **Widgets/Siri "Abrir app"**: hoy usan `market://launch` (no funciona aquí). Pasarlos por el companion (WebSocket 7790 con el token del App Group) o limitarlos a apps con deep link https.
3. Teclado hexadecimal (0–9, A–F) al escribir el código del control en el iPhone (ese código lo genera Google y no puede ser solo numérico).
4. Probar escribir texto (IME) desde el iPhone.
5. Diseño de la app iPhone al nivel del launcher.
6. Auditoría final del repo; hallazgos abiertos: token del companion en claro por `ws://`.

## Decisiones de esta sesión

- Launcher: "Seguir viendo" (últimas 5 apps abiertas, sin las cerradas con "Cerrar app") arriba; "Tus favoritos" (máx. 9, sin las que ya están en Seguir viendo, por último uso) abajo; siempre 5 tarjetas enteras por fila con flechas; "Todas las apps" junto al título; entradas HDMI en un desplegable arriba a la derecha (con el nombre CEC del equipo).
- Sin apps ocultas ni columnas ni reordenar (quitado en TV e iPhone).
- Banners originales de las apps (no hay variantes de modo oscuro).
- Automatizaciones: Atajos de iOS. Home Assistant: integración oficial `androidtv_remote`.
