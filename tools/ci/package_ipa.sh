#!/usr/bin/env bash
# Packages an unsigned Runner.app into an .ipa that SideStore re-signs.
#   tools/ci/package_ipa.sh <path/to/Runner.app> <out.ipa>
set -euo pipefail
app="$1"; out="$2"
[ -d "$app" ] || { echo "missing $app"; exit 1; }
work=$(mktemp -d)
mkdir -p "$work/Payload"
cp -R "$app" "$work/Payload/"
(cd "$work" && zip -qry "$OLDPWD/$out" Payload)
ls -la "$out"
