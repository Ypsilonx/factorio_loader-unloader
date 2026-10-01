#!/usr/bin/env bash
# Vytvoří junction %APPDATA%/Factorio/mods/Storage_optimizer → složka modu v repozitáři,
# aby hra načítala rozpracovanou verzi přímo z repozitáře (pro ruční hraní a FMTK debugger).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINK="$APPDATA/Factorio/mods/Storage_optimizer"
if [ -e "$LINK" ]; then
  echo "Už existuje: $LINK"
  exit 0
fi
cmd //c mklink /J "$(cygpath -w "$LINK")" "$(cygpath -w "$ROOT/Storage_optimizer")"
