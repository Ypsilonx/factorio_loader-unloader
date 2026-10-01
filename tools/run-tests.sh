#!/usr/bin/env bash
# Spustí integrační testy v headless Factoriu: vytvoří mapu s modem a testovacím modem,
# odsimuluje ticky a vyhodnotí řádky SO-TEST z logu.
# Použití: tools/run-tests.sh [vanilla|space-age]   (cestu k Factoriu lze změnit proměnnou FACTORIO_EXE)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_EXE:-C:/STEAM/steamapps/common/Factorio/bin/x64/factorio.exe}"
VARIANT="${1:-vanilla}"
RUN="$ROOT/.test-run/$VARIANT"
RUN_W="$(cygpath -m "$RUN")"

rm -rf "$RUN"
mkdir -p "$RUN/mods" "$RUN/write-data"
cp -r "$ROOT/Storage_optimizer" "$RUN/mods/Storage_optimizer"
cp -r "$ROOT/tests/storage-optimizer-tests" "$RUN/mods/storage-optimizer-tests"

SA=false
[ "$VARIANT" = "space-age" ] && SA=true
cat > "$RUN/mods/mod-list.json" <<JSON
{"mods":[
  {"name":"base","enabled":true},
  {"name":"elevated-rails","enabled":$SA},
  {"name":"quality","enabled":$SA},
  {"name":"space-age","enabled":$SA},
  {"name":"Storage_optimizer","enabled":true},
  {"name":"storage-optimizer-tests","enabled":true}
]}
JSON
# Oddělená write-data složka, aby testy nepřepisovaly log a konfiguraci hráče.
cat > "$RUN/config.ini" <<INI
[path]
read-data=__PATH__executable__/../../data
write-data=$RUN_W/write-data
INI

ARGS=(--config "$RUN_W/config.ini" --mod-directory "$RUN_W/mods")
"$FACTORIO" "${ARGS[@]}" --create "$RUN_W/test.zip" > "$RUN/create.log" 2>&1 || true
if [ ! -f "$RUN/test.zip" ]; then
  echo "Vytvoření mapy selhalo:"
  grep -A12 -E "Error|error" "$RUN/create.log" | head -40
  exit 1
fi
"$FACTORIO" "${ARGS[@]}" --benchmark "$RUN_W/test.zip" --benchmark-ticks 1500 --disable-audio > "$RUN/bench.log" 2>&1 || true
grep -E "SO-TEST|Error" "$RUN/bench.log" | sed 's/.*SO-TEST/SO-TEST/'
grep -q "SO-TEST DONE pass=[0-9]* fail=0 " "$RUN/bench.log"
