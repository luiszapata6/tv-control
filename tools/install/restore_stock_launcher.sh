#!/usr/bin/env bash
# Re-enables the stock launcher(s) that install_launcher.sh --make-default disabled.
#   ./tools/install/restore_stock_launcher.sh <TV_IP> [--uninstall]
set -euo pipefail
PKG=com.luiszapata.tvcontrol.tv_launcher
ip="${1:?usage: restore_stock_launcher.sh <TV_IP> [--uninstall]}"
target="$ip:5555"
adb connect "$target" >/dev/null
list="$(dirname "$0")/.disabled-launchers"
pkgs=(com.google.android.tvlauncher com.google.android.apps.tv.launcherx com.hisense.tv.launcher com.jamdeo.tv.vod)
if [ -f "$list" ]; then pkgs=(); while IFS= read -r l; do pkgs+=("$l"); done < <(sort -u "$list"); fi
for p in "${pkgs[@]}"; do
  adb -s "$target" shell pm enable "$p" >/dev/null 2>&1 && echo "→ Reactivado $p" || true
done
if [ "${2:-}" = --uninstall ]; then adb -s "$target" uninstall "$PKG" && echo "→ Launcher desinstalado"; fi
rm -f "$list"
adb -s "$target" shell input keyevent KEYCODE_HOME
echo "✓ Launcher de fábrica restaurado."
