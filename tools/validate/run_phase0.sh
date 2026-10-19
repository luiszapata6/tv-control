#!/usr/bin/env bash
# Fase 0: valida tu TV real. Uso:  ./tools/validate/run_phase0.sh [IP_DE_LA_TV]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
if [ ! -d .venv ]; then
  python3 -m venv .venv
  .venv/bin/pip install -q --upgrade pip
  .venv/bin/pip install -q -r requirements.txt
fi
exec .venv/bin/python phase0.py "$@"
