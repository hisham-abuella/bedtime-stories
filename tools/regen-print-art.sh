#!/usr/bin/env bash
# Regenerate every illustration at 1536px for print.
#
# The books ship 1024px art, which is 241dpi inside a 108mm box — below the
# 300dpi a print-on-demand printer requires. Same prompts, same seeds, so the
# pictures come back in the same composition, just with enough pixels.
#
#   tools/regen-print-art.sh        # fills art-hi/, skipping what is there
set -uo pipefail
cd "$(dirname "$0")/.."
export SIZE=1536
mkdir -p art-hi
echo "== zoo"            && DEST="$PWD/art-hi/images-v1"   zsh source/gen-pages.sh
echo "== susu"           && DEST="$PWD/art-hi/images-susu" zsh source/gen-susu.sh
echo "== muslim books"   && ART_ROOT="$PWD/art-hi"         zsh source/gen-muslim-books.sh
echo "== done"
find art-hi -name '*.png' | wc -l | xargs echo "images at 1536px:"
