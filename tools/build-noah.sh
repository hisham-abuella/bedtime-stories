#!/usr/bin/env bash
# Noah's printed set: the same books, with his name on the pages, and Loza —
# his cat — in the place Susu takes in Yusuf's volume.
#
#   tools/build-noah.sh
#
#   print/noah/arabic/     fusha
#   print/noah/egyptian/   مصري
#
#   loza-board                     180mm square, for printing at home on card
#   vol-noah-first-words-*         Bismillah · Alhamdulillah · Allah Made It · Our Prophet ﷺ
#   vol-noah-animals-colours-*     Black & White · Fifteen Colours · Loza the Cat
#
# The volumes are Lulu's 8.5in Square, interior and cover as separate uploads,
# exactly as build-volumes.sh makes Yusuf's. Only the name and one story differ.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BASE="https://hisham-abuella.github.io/bedtime-stories"
NAME=(--name "Noah" --name-ar "نوح")

# Loza's print-weight art. The other books' copies are made by build-print.sh
# and build-lulu.sh; Loza's are made here too so this script stands alone.
mkdir -p input/img/images-loza input/img-hi/images-loza
for png in images-loza/*.png; do
  b=$(basename "${png%.png}")
  out="input/img/images-loza/$b.jpg"
  [[ -f $out && $out -nt $png ]] || sips -s format jpeg -s formatOptions 88 "$png" --out "$out" >/dev/null
  hi="art-hi/images-loza/$b.png"
  if [[ ! -f $hi ]]; then
    echo "missing 1536px: $hi — run: DEST=\$PWD/art-hi/images-loza SIZE=1536 zsh source/gen-loza.sh" >&2
    exit 1
  fi
  out="input/img-hi/images-loza/$b.jpg"
  # same resample as build-lulu.sh: lands 300-600ppi in every box
  [[ -f $out && $out -nt $hi ]] || sips -Z 1400 -s format jpeg -s formatOptions 90 "$hi" --out "$out" >/dev/null
done

mkdir -p build print/noah/arabic print/noah/egyptian

pdf() {   # pdf <build-html> <dest-pdf>
  "$CHROME" --headless --no-pdf-header-footer --print-to-pdf="$2" "file://$PWD/$1" 2>/dev/null
  printf '  %-60s %s\n' "$2" "$(du -h "$2" | cut -f1)"
}
dest() { case " $* " in *" --dialect eg "*) echo print/noah/egyptian ;; *) echo print/noah/arabic ;; esac; }

board() {  # board <suffix> [flags...]
  local suffix=$1; shift
  node tools/make-print.js books/loza.html "build/loza$suffix.html" \
       --url "$BASE/books/loza.html" --qr input/qr/qr-loza.svg --board --art images "${NAME[@]}" "$@"
  pdf "build/loza$suffix.html" "$(dest "$@")/loza$suffix.pdf"
}
board "-board"
board "-board-eg" --dialect eg

FIRST="books/bismillah.html,books/alhamdulillah.html,books/khalaqa.html,books/nabina.html"
ANIMALS="books/black-white-zoo.html,books/loza.html"

vol() {    # vol <slug> <books> <title-en> <title-ar> <suffix> [flags...]
  local slug=$1 books=$2 ten=$3 tar=$4 suffix=$5; shift 5
  node tools/make-print.js "$books" "build/$slug$suffix.html" \
       --url "$BASE/" --lulu --art images --volume "$ten" --volume-ar "$tar" "${NAME[@]}" "$@" >/dev/null
  pdf "build/$slug$suffix.html" "$(dest "$@")/$slug$suffix.pdf"
}
for v in "vol-noah-first-words|$FIRST|First Words|أوّلُ الكلمات" \
         "vol-noah-animals-colours|$ANIMALS|Animals and Colours|الحيوانات والألوان"; do
  IFS='|' read -r slug books ten tar <<< "$v"
  vol "$slug" "$books" "$ten" "$tar" "-interior"
  vol "$slug" "$books" "$ten" "$tar" "-cover"       --cover
  vol "$slug" "$books" "$ten" "$tar" "-interior-eg" --dialect eg
  vol "$slug" "$books" "$ten" "$tar" "-cover-eg"    --cover --dialect eg
done
