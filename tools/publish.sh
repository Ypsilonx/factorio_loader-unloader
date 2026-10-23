#!/usr/bin/env bash
# Nahraje novou verzi modu na mods.factorio.com přes Mod upload API (sestaví zip přes tools/package.sh).
# Použití: tools/publish.sh [--details | --details-only]
#   --details       navíc aktualizuje na portálu popis z docs/mod-portal.md a krátký popis z info.json
#   --details-only  jen aktualizuje popis, novou verzi nenahrává
# API klíč (https://factorio.com/profile → API keys, oprávnění „ModPortal: Upload Mods“, pro --details
# i „ModPortal: Edit Mods“): proměnná FACTORIO_API_KEY, jinak soubor FACTORIO_API_KEY_FILE (výchozí
# ~/.factorio-api-key/all_api_key.txt – klíče leží ve složce ~/.factorio-api-key/). Nikdy ne do repozitáře.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="https://mods.factorio.com/api"
MOD="Storage_optimizer"
KEY_FILE="${FACTORIO_API_KEY_FILE:-$HOME/.factorio-api-key/all_api_key.txt}"
KEY="${FACTORIO_API_KEY:-$(cat "$KEY_FILE" 2>/dev/null || true)}"
KEY="$(printf '%s' "$KEY" | tr -d '\r\n ')"
[ -z "$KEY" ] && { echo "Chybí API klíč: FACTORIO_API_KEY nebo soubor $KEY_FILE"; exit 1; }

MODE="${1:-}"

# Nahraje verzi z info.json; odmítne verzi, která na portálu už je nebo chybí v changelogu.
upload_release() {
  local version zip init url result
  version=$(grep -oE '"version"[^"]*"[^"]+"' "$ROOT/$MOD/info.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  grep -q "^Version: $version$" "$ROOT/$MOD/changelog.txt" || { echo "changelog.txt nemá sekci $version"; exit 1; }
  if curl -sS "$API/mods/$MOD" | grep -q "\"version\":\"$version\""; then
    echo "Verze $version už na portálu je – zvyš version v info.json."
    exit 1
  fi
  if [ -n "$(git -C "$ROOT" status --porcelain -- "$MOD")" ]; then
    echo "Pozor: $MOD má necommitnuté změny, nahrávají se tak, jak jsou."
  fi

  zip="$(bash "$ROOT/tools/package.sh" | tail -1)"
  echo "Nahrávám $zip"
  init="$(curl -sS -H "Authorization: Bearer $KEY" -F "mod=$MOD" "$API/v2/mods/releases/init_upload")"
  url="$(printf '%s' "$init" | grep -oE '"upload_url" *: *"[^"]+"' | sed -E 's/.*"(https[^"]+)"/\1/')"
  [ -z "$url" ] && { echo "init_upload selhal: $init"; exit 1; }
  result="$(curl -sS -F "file=@$(cygpath -m "$zip")" "$url")"
  printf '%s' "$result" | grep -q '"success" *: *true' || { echo "Nahrání selhalo: $result"; exit 1; }
  echo "Verze $version nahrána: https://mods.factorio.com/mod/$MOD"
}

# Aktualizuje krátký popis (info.json) a dlouhý popis (docs/mod-portal.md). Texty jdou curlu ze souborů –
# argument by v Git Bash prošel kódovou stránkou Windows a rozbil znaky jako „–“.
update_details() {
  local summary_file result
  summary_file="$(mktemp)"
  grep -oE '"description" *: *"[^"]*"' "$ROOT/$MOD/info.json" \
    | sed -E 's/^"description" *: *"(.*)"$/\1/' | tr -d '\n' >"$summary_file"
  result="$(curl -sS -H "Authorization: Bearer $KEY" -F "mod=$MOD" -F "summary=<$(cygpath -m "$summary_file")" \
    -F "description=<$(cygpath -m "$ROOT/docs/mod-portal.md")" "$API/v2/mods/edit_details")"
  rm -f "$summary_file"
  printf '%s' "$result" | grep -q '"success" *: *true' || { echo "Úprava popisu selhala: $result"; exit 1; }
  echo "Popis na portálu aktualizován."
}

case "$MODE" in
  "") upload_release ;;
  --details) upload_release; update_details ;;
  --details-only) update_details ;;
  *) echo "Neznámý přepínač: $MODE"; exit 1 ;;
esac
