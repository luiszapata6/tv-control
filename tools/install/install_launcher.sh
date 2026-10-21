#!/usr/bin/env bash
# Installs the TV Control launcher on the TV over ADB (Wi-Fi) and grants what
# it needs. Run from a Mac with Android platform-tools (brew install android-platform-tools).
#
#   ./tools/install/install_launcher.sh <TV_IP> [path/to/launcher.apk] [--make-default]
#
# Without an APK path it downloads the latest build from the GitHub release.
# --make-default disables the stock launcher so Home opens TV Control
# (undo with ./tools/install/restore_stock_launcher.sh <TV_IP>).
set -euo pipefail

PKG=com.luiszapata.tvcontrol.tv_launcher
REPO=luiszapata6/tv-control
STOCK_LAUNCHERS=(com.google.android.tvlauncher com.google.android.apps.tv.launcherx com.hisense.tv.launcher com.jamdeo.tv.vod)

ip="${1:?usage: install_launcher.sh <TV_IP> [apk] [--make-default]}"; shift
apk=""; make_default=0
for a in "$@"; do
  case "$a" in
    --make-default) make_default=1 ;;
    *) apk="$a" ;;
  esac
done

command -v adb >/dev/null || { echo "Falta adb: brew install android-platform-tools"; exit 1; }

if [ -z "$apk" ]; then
  apk="$(mktemp -d)/TVControl-launcher.apk"
  echo "→ Descargando el APK más reciente…"
  curl -fL --progress-bar -o "$apk" "https://github.com/$REPO/releases/download/latest/TVControl-launcher.apk"
fi

target="$ip:5555"
echo "→ Conectando a $target (acepta el aviso 'Permitir depuración USB' en la TV si aparece)…"
adb connect "$target" >/dev/null
for _ in $(seq 1 30); do
  state=$(adb -s "$target" get-state 2>/dev/null || true)
  [ "$state" = device ] && break
  sleep 1
done
[ "${state:-}" = device ] || { echo "La TV no autorizó la conexión. Activa 'Depuración por red' en Opciones de desarrollador y reintenta."; exit 1; }
sh() { adb -s "$target" shell "$@"; }

# The first install keeps a snapshot of the stock state for the rollback.
if ! ls -d "$(dirname "$0")/backups/$ip"/*/ >/dev/null 2>&1; then
  echo "→ Guardando el estado actual de la TV (rollback)…"
  "$(dirname "$0")/snapshot_tv.sh" "$ip"
fi

echo "→ Instalando $(basename "$apk")…"
adb -s "$target" install -r -g "$apk"

echo "→ Permisos: historial de uso y 'ahora suena'…"
sh appops set "$PKG" GET_USAGE_STATS allow || true
sh cmd notification allow_listener "$PKG/$PKG.core.NowPlayingListenerService" || \
  echo "  (no se pudo habilitar el listener; actívalo en Ajustes › Apps › Acceso especial › Notificaciones)"

echo "→ Iniciando el servicio de compañía…"
sh am start -n "$PKG/.MainActivity" >/dev/null

# Updating the app clears Android's preferred home: set it again whenever this
# launcher is (or becomes) the home screen, or Home opens a chooser.
if [ "$make_default" = 1 ] || [ -f "$(dirname "$0")/.disabled-launchers" ]; then
  sh cmd package set-home-activity --user 0 "$PKG/.MainActivity" >/dev/null 2>&1 || true
fi

if [ "$make_default" = 1 ]; then
  for p in "${STOCK_LAUNCHERS[@]}"; do
    if sh pm list packages | tr -d '\r' | grep -qx "package:$p"; then
      echo "→ Desactivando launcher de fábrica $p"
      sh pm disable-user --user 0 "$p" >/dev/null
      echo "$p" >> "$(dirname "$0")/.disabled-launchers"
    fi
  done
  sh input keyevent KEYCODE_HOME
fi

echo "✓ Listo. En el iPhone abre TV Control › Apps para vincular el launcher."
