#!/usr/bin/env bash
# Uploads cloudflare/dist/goshyar/<version>/ to the R2 bucket, file by file, with wrangler.
#
#   npx wrangler@4 login                       # once; stores your credentials locally, not in the repo
#   python3 cloudflare/scripts/build_packs.py --version v1
#   cloudflare/scripts/upload.sh v1
#
# packs.json is uploaded last, so the app never sees an index that points at missing files.
set -euo pipefail

VERSION="${1:-v1}"
BUCKET="${GOSHYAR_BUCKET:-goshyar-assets}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dist"
DIR="$ROOT/goshyar/$VERSION"

if [ ! -f "$DIR/packs.json" ]; then
  echo "Missing $DIR/packs.json — run build_packs.py first." >&2
  exit 1
fi

cd "$ROOT"
find "goshyar/$VERSION" -type f ! -name packs.json | sort | while read -r key; do
  npx --yes wrangler@4 r2 object put "$BUCKET/$key" --file "$key" --remote \
    --cache-control "public, max-age=31536000, immutable" >/dev/null
  echo "uploaded $key"
done
npx --yes wrangler@4 r2 object put "$BUCKET/goshyar/$VERSION/packs.json" --file "goshyar/$VERSION/packs.json" \
  --remote --content-type "application/json; charset=utf-8" --cache-control "public, max-age=300" >/dev/null
echo "uploaded goshyar/$VERSION/packs.json"
