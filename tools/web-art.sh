#!/usr/bin/env bash
# Make a book's web pictures from its high-resolution masters.
#
#   tools/web-art.sh <slug> [page …]
#
# Every page is drawn once, at 1536px, into art-hi/images-<slug>/ (DEST=…
# SIZE=1536 zsh source/gen-<slug>.sh). The web book shows images-<slug>/*.png,
# the same pictures shrunk to 1024px, so the screen and the print editions can
# never drift apart — a re-render at a new size would be a different picture.
#
# Name pages to update only those. Do that on books drawn before this rule
# (Loza, Susu, the Muslim books): their art-hi masters are separate 1536px
# re-renders, not the pictures on the web, and must not replace them.
set -euo pipefail
cd "$(dirname "$0")/.."
slug=${1:?usage: tools/web-art.sh <slug> [page …]}
shift
src=art-hi/images-$slug
[[ -d $src ]] || { echo "no $src — draw the pages first: DEST=\$PWD/$src SIZE=1536 zsh source/gen-$slug.sh" >&2; exit 1; }
mkdir -p "images-$slug"
n=0
if (( $# )); then masters=(); for k in "$@"; do masters+=("$src/$k.png"); done
else masters=("$src"/*.png); fi
for hi in "${masters[@]}"; do
  [[ -f $hi ]] || { echo "no $hi" >&2; exit 1; }
  out=images-$slug/$(basename "$hi")
  [[ -f $out && $out -nt $hi ]] && continue
  sips -Z 1024 "$hi" --out "$out" >/dev/null
  n=$((n + 1))
done
echo "images-$slug: $n picture(s) updated from $src"
