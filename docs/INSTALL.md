# Instalación

Hay tres piezas: el **launcher** (va en la TV), la **app del iPhone** y, si quieres, la **app de barra de menú** para Mac. Todas se descargan de la release `latest` del repo, que CI regenera en cada push a `main` cuando todo pasa:
https://github.com/luiszapata6/tv-control/releases/tag/latest

| Archivo | Qué es |
| --- | --- |
| `TVControl-launcher.apk` | Launcher + servicio de compañía para la TV |
| `TVControl.ipa` | App del iPhone, sin firmar (la firma SideStore) |
| `TVControl-mac.zip` | App de barra de menú para Mac |

## 0. Validación con tu TV (una sola vez, recomendado)

Esto confirma que el protocolo funciona con tu Hisense antes de instalar nada. En el Mac, con la TV encendida y en la misma Wi-Fi:

```bash
cd ~/Development/tv-control
./tools/validate/run_phase0.sh            # o: ./tools/validate/run_phase0.sh 192.168.1.50
```

El script crea su propio entorno de Python, empareja con el código que aparece en la TV, prueba botones, volumen, texto y apertura de apps, y deja un reporte en `tools/validate/out/phase0-report.md`.

## 1. Launcher en la TV

1. En la TV: **Ajustes › Sistema › Acerca de › Compilación**: pulsa OK 7 veces para activar las opciones de desarrollador.
2. **Ajustes › Sistema › Opciones de desarrollador**: activa **Depuración USB** y, si aparece, **Depuración por red/ADB inalámbrico**.
3. En el Mac instala las herramientas de Android: `brew install android-platform-tools`.
4. Instala y da permisos:

```bash
./tools/install/install_launcher.sh 192.168.1.50                  # instala y da permisos
./tools/install/install_launcher.sh 192.168.1.50 --make-default   # además lo deja como pantalla de inicio
```

La primera vez la TV pregunta **"¿Permitir depuración?"**: marca *Permitir siempre* y acepta.

`--make-default` desactiva el launcher de fábrica (no lo borra). Para volver al de fábrica:

```bash
./tools/install/restore_stock_launcher.sh 192.168.1.50             # reactiva el de fábrica
./tools/install/restore_stock_launcher.sh 192.168.1.50 --uninstall # y quita TV Control
```

## 2. App del iPhone con SideStore

1. Instala SideStore siguiendo su guía oficial (https://sidestore.io). Requiere un Apple ID gratuito y, la primera vez, un computador.
2. Descarga `TVControl.ipa` en el iPhone (desde la release) y ábrelo con SideStore (**My Apps › +**).
3. SideStore renueva la firma solo cada 7 días mientras tengas su VPN/WireGuard o LocalDevVPN activo; no hace falta conectarlo al computador de nuevo.
4. Abre TV Control, elige tu TV y escribe el código que aparece en pantalla.

**Límites de una cuenta gratuita de Apple** que afectan a esta app:
- SideStore cuenta la app y su extensión de widgets como identificadores de app: TV Control usa 2 (app + widgets). Con una cuenta gratuita hay un máximo de 3 apps activas a la vez (SideStore incluido) y 10 identificadores por semana.
- **Wake-on-LAN por broadcast no está disponible**: iOS exige un permiso (multicast) que Apple solo da a cuentas de pago. La app envía el paquete directo a la IP de la TV y reintenta conectarse; si tu TV apaga la red en reposo, actívala con el control físico o habilita *Encendido por red / Wake on Wi-Fi* en la TV.

### Widgets, Centro de control, Siri y Actividad en vivo
- **Widget**: mantén presionada la pantalla de inicio › **+** › TV Control.
- **Centro de control** (iOS 18): edita el Centro de control › *Añadir control* › TV Control (encender, silenciar, volumen).
- **Siri**: "Oye Siri, apaga la TV con TV Control", "Abre Netflix en la TV con TV Control". También aparecen en la app Atajos.
- **Actividad en vivo**: se muestra mientras el control está conectado; se apaga en *Ajustes de la app › Actividad en vivo*.

Abre la app al menos una vez después de vincular la TV: es la que comparte el certificado con los widgets.

## 3. Conectar el iPhone con el launcher

En la app: pestaña **Apps › Conectar**. La TV muestra un código de 6 dígitos; escríbelo. Desde entonces verás tus apps reales con su ícono, podrás reordenar el inicio de la TV y ver lo que se está reproduciendo. Para desvincular todos los dispositivos: en la TV, **Ajustes del launcher › Olvidar dispositivos** (pulsa dos veces para confirmar).

## 4. App para Mac

1. Descarga y descomprime `TVControl-mac.zip`; mueve **TV Control.app** a Aplicaciones.
2. No está notarizada: la primera vez haz **clic derecho › Abrir › Abrir**.
3. Aparece un ícono de TV en la barra de menú. Clic izquierdo abre el control; clic derecho, *Salir*.
4. El Mac se empareja con la TV por su cuenta (mismo flujo del código en pantalla).

## 5. Home Assistant (opcional)

No hace falta nada de este proyecto: la integración oficial **Android TV Remote** habla el mismo protocolo (librería androidtvremote2).

1. Home Assistant › Ajustes › Dispositivos y servicios › *Agregar integración* › **Android TV Remote**.
2. La TV aparece sola por mDNS; escribe el código de 6 caracteres que muestra.
3. Obtienes encender/apagar, teclas, volumen y abrir apps por enlace. La lista de apps instaladas y el uso solo están en el launcher (companion), que Home Assistant no usa.

## Problemas comunes

| Síntoma | Qué hacer |
| --- | --- |
| La app no encuentra la TV | iPhone y TV en la misma red; permite *Red local* en Ajustes › TV Control. Usa *Ingresar IP* si tu router bloquea mDNS. |
| "La TV ya no reconoce este iPhone" | Se borró el emparejamiento en la TV: vuelve a vincularla desde Ajustes de la app. |
| Las apps no muestran ícono | El launcher no está conectado: pestaña Apps › Conectar. |
| "Ahora suena" vacío | En la TV: Ajustes › Apps › Acceso especial › Acceso a notificaciones › TV Control. El script de instalación lo intenta activar. |
| `adb connect` falla | Revisa la IP de la TV y que la depuración por red siga activa (algunas TVs la apagan al reiniciar). |
