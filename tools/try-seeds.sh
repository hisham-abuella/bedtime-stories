#!/bin/zsh
# Try one page with several seeds, and lay them out side by side to pick from.
#
#   tools/try-seeds.sh <slug> <page> <first-seed> [count]
#
# Reads the page's `gen <page> "<prompt>" <seed>` line from source/gen-<slug>.sh,
# so the prompt is exactly the book's (character, style and negatives
# included), and draws it at 1536px with <count> seeds from <first-seed> up
# (default 4) into build/<slug>-try/<page>-<seed>.png. Then it makes
# build/<slug>-try/<page>-sheet.png with each seed written under its picture.
#
# Pick one, set that seed on the page's gen line, and copy the picture into
# art-hi/images-<slug>/<page>.png — it is already the final master, so there
# is nothing to redraw. Then tools/web-art.sh <slug> <page>.
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO"
slug=${1:?usage: tools/try-seeds.sh <slug> <page> <first-seed> [count]}
page=${2:?page key}; first=${3:?first seed}; count=${4:-4}
script=source/gen-$slug.sh
[[ -f $script ]] || { echo "no $script" >&2; exit 1; }
grep -qE "gen +$page " "$script" || { echo "no 'gen $page' line in $script" >&2; exit 1; }

out=$REPO/build/$slug-try
mkdir -p "$out"
seeds=($(seq $first $((first + count - 1))))
# Run the book's own script in a sandbox: its variables and gen() are defined
# as written, the line for this page is kept, every other gen line is dropped,
# and gen() is replaced by one that draws each seed instead of the fixed one.
tmp=$(mktemp -t try-seeds).zsh
pre='^[[:space:]]*(NEG="[^"]*"[[:space:]]+)?(SIZE=[0-9]+[[:space:]]+)?gen[[:space:]]+'
any="$pre"'[A-Za-z0-9_-]+[[:space:]]+"'      # every page's gen line
one="$pre$page"'[[:space:]]+"'                # this page's
{
  grep -vE "$any" "$script" | grep -v 'IMAGES DONE'
  cat <<'FN'
gen () {
  for s in ${=TRY_SEEDS}; do
    [[ -f "$TRY_OUT/$1-$s.png" ]] && { echo "have $1-$s"; continue; }
    $CLI generate --model z_image_turbo_1.0_q8p.ckpt --prompt "$2" --negative-prompt "$NEG" \
      --width 1536 --height 1536 --seed $s --output "$TRY_OUT/$1-$s.png" >/dev/null 2>&1 \
      && echo "drew $1-$s" || echo "FAIL $1-$s"
  done
}
FN
  grep -E "$one" "$script"
} > "$tmp"
TRY_OUT=$out TRY_SEEDS="${seeds[*]}" DEST=$out zsh "$tmp"
rm -f "$tmp"

python3 "$REPO/tools/contact-sheet.py" "$out/$page-sheet.png" $(for s in $seeds; print "$out/$page-$s.png")
echo "pick one: $out/$page-sheet.png"
