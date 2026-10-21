#!/usr/bin/env bash
# Saves the TV state that installing the launcher can change, so
# restore_stock_launcher.sh can put it back exactly.
#   ./tools/install/snapshot_tv.sh <TV_IP>
# Writes tools/install/backups/<TV_IP>/<fecha>/. The restore uses the oldest one
# (the state before the first install).
set -euo pipefail
ip="${1:?usage: snapshot_tv.sh <TV_IP>}"
target="$ip:5555"
adb connect "$target" >/dev/null
for _ in $(seq 1 30); do
  [ "$(adb -s "$target" get-state 2>/dev/null || true)" = device ] && break
  sleep 1
done
[ "$(adb -s "$target" get-state 2>/dev/null || true)" = device ] || { echo "La TV no autorizó la conexión ADB."; exit 1; }
sh() { adb -s "$target" shell "$@" | tr -d '\r'; }

root="$(dirname "$0")/backups/$ip"
dir="$root/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dir"
sh cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1 > "$dir/home.txt"
sh pm list packages -d | sed 's/^package://' | sort > "$dir/disabled.txt"
sh pm list packages | sed 's/^package://' | sort > "$dir/packages.txt"
sh settings get secure enabled_notification_listeners > "$dir/notification_listeners.txt"
sh getprop ro.build.fingerprint > "$dir/build.txt"
[ -s "$dir/home.txt" ] || { echo "No pude leer el launcher actual."; exit 1; }
echo "✓ Estado guardado en $dir (launcher actual: $(cat "$dir/home.txt"))"
