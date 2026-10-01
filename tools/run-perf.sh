#!/usr/bin/env bash
# Výkonové srovnání: N dvojic beden bez spojení (idle), se Storage optimizerem (mover)
# a s dvojicí vanilla loaderů (loader). Vypíše průměrný čas ticku a počet přesunutých kusů.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_EXE:-C:/STEAM/steamapps/common/Factorio/bin/x64/factorio.exe}"
N="${PERF_N:-1000}"
TICKS=3600

printf "%-8s | %10s | %s\n" "režim" "ms/tick" "přesunuto kusů"
for MODE in ${PERF_MODES:-idle mover loader}; do
  RUN="$ROOT/.test-run/perf-$MODE"
  RUN_W="$(cygpath -m "$RUN")"
  rm -rf "$RUN"
  mkdir -p "$RUN/mods" "$RUN/write-data"
  cp -r "$ROOT/Storage_optimizer" "$RUN/mods/Storage_optimizer"
  cp -r "$ROOT/tests/perf/so-perf" "$RUN/mods/so-perf"
  echo "return \"$MODE\"" > "$RUN/mods/so-perf/mode.lua"
  echo "return $N" > "$RUN/mods/so-perf/count.lua"
  cat > "$RUN/mods/mod-list.json" <<JSON
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"Storage_optimizer","enabled":true},{"name":"so-perf","enabled":true}]}
JSON
  cat > "$RUN/config.ini" <<INI
[path]
read-data=__PATH__executable__/../../data
write-data=$RUN_W/write-data
INI
  ARGS=(--config "$RUN_W/config.ini" --mod-directory "$RUN_W/mods")
  "$FACTORIO" "${ARGS[@]}" --create "$RUN_W/perf.zip" > "$RUN/create.log" 2>&1 || true
  if [ ! -f "$RUN/perf.zip" ]; then
    echo "Vytvoření mapy ($MODE) selhalo"
    grep -A12 Error "$RUN/create.log"
    exit 1
  fi
  "$FACTORIO" "${ARGS[@]}" --benchmark "$RUN_W/perf.zip" --benchmark-ticks $TICKS --disable-audio > "$RUN/bench.log" 2>&1 || true
  MS=$(grep -oE "Performed [0-9]+ updates in [0-9.]+ ms" "$RUN/bench.log" | grep -oE "[0-9.]+ ms" | grep -oE "[0-9.]+")
  MOVED=$(grep -oE "SO-PERF moved=[0-9]+" "$RUN/bench.log" | tail -1 | grep -oE "[0-9]+$" || echo "?")
  printf "%-8s | %10s | %s\n" "$MODE" "$(awk "BEGIN { printf \"%.4f\", $MS / $TICKS }")" "$MOVED"
done
