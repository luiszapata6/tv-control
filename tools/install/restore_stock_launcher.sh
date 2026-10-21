#!/usr/bin/env bash
# Puts the TV back as it was before the first install_launcher.sh: re-enables
# the packages that were enabled then, restores the home app and the
# notification listeners (from the oldest snapshot in backups/<TV_IP>/).
#   ./tools/install/restore_stock_launcher.sh <TV_IP> [--uninstall]
set -euo pipefail
PKG=com.luiszapata.tvcontrol.tv_launcher
ip="${1:?usage: restore_stock_launcher.sh <TV_IP> [--uninstall]}"
target="$ip:5555"
adb connect "$target" >/dev/null
# </dev/null: adb shell would otherwise eat the stdin of the while-read loop below.
sh() { adb -s "$target" shell "$@" </dev/null | tr -d '\r'; }
here="$(dirname "$0")"
snap="$(ls -d "$here/backups/$ip"/*/ 2>/dev/null | sort | head -1 || true)"

if [ -n "$snap" ]; then
  echo "→ Usando el estado guardado en $snap"
  # Enabled before, disabled now: re-enable.
  comm -13 "$snap/disabled.txt" <(sh pm list packages -d | sed 's/^package://' | sort) | while IFS= read -r p; do
    sh pm enable "$p" >/dev/null 2>&1 && echo "→ Reactivado $p" || true
  done
  home="$(cat "$snap/home.txt")"
  [[ "$home" == */* ]] && sh cmd package set-home-activity "$home" >/dev/null 2>&1 && echo "→ Inicio: $home" || true
  listeners="$(cat "$snap/notification_listeners.txt")"
  if [ "$listeners" = null ]; then sh settings delete secure enabled_notification_listeners >/dev/null; else sh settings put secure enabled_notification_listeners "'$listeners'"; fi
else
  # No snapshot: re-enable the known stock launchers.
  list="$here/.disabled-launchers"
  pkgs=(com.google.android.tvlauncher com.google.android.apps.tv.launcherx com.hisense.tv.launcher com.jamdeo.tv.vod)
  if [ -f "$list" ]; then pkgs=(); while IFS= read -r l; do pkgs+=("$l"); done < <(sort -u "$list"); fi
  for p in "${pkgs[@]}"; do
    sh pm enable "$p" >/dev/null 2>&1 && echo "→ Reactivado $p" || true
  done
fi
if [ "${2:-}" = --uninstall ]; then adb -s "$target" uninstall "$PKG" && echo "→ Launcher desinstalado"; fi
rm -f "$here/.disabled-launchers"
sh input keyevent KEYCODE_HOME
echo "✓ TV restaurada."
