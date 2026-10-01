#!/usr/bin/env bash
# Sestaví zip modu pro mod portál: dist/Storage_optimizer_<verze>.zip s kořenovou složkou Storage_optimizer_<verze>/.
# Používá PowerShell 7 (Compress-Archive v pwsh zapisuje cesty s lomítky, jak Factorio vyžaduje).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(grep -oE '"version"[^"]*"[^"]+"' "$ROOT/Storage_optimizer/info.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
NAME="Storage_optimizer_$VERSION"
STAGE="$ROOT/dist/stage"
rm -rf "$STAGE" "$ROOT/dist/$NAME.zip"
mkdir -p "$STAGE"
cp -r "$ROOT/Storage_optimizer" "$STAGE/$NAME"
pwsh -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$STAGE/$NAME")' -DestinationPath '$(cygpath -w "$ROOT/dist/$NAME.zip")'"
rm -rf "$STAGE"
echo "$ROOT/dist/$NAME.zip"
