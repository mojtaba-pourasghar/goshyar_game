#!/bin/bash
# یک تصویر تولیدشده را از پوشه‌ی موقت ابزار به res/drawable می‌برد.
#   tools/install_gen.sh <blob.jpg> <img_horse>
set -e
SRC="$1"; NAME="$2"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp "$SRC" "$ROOT/art/generated/$NAME.jpg"
convert "$SRC" -filter Lanczos -resize 512x512 "$ROOT/app/src/main/res/drawable/$NAME.png"
echo "✅ $NAME  $(identify -format '%wx%h' "$ROOT/app/src/main/res/drawable/$NAME.png")"
