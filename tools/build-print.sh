#!/usr/bin/env bash
# Rebuild every printed edition from the books themselves.
#
#   tools/build-print.sh
#
# Four editions per story — A5 and board, each with the drawn artwork or the
# generated illustrations. See README "Printed editions" for what to print on.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BASE="https://hisham-abuella.github.io/bedtime-stories"

# Print-weight copies of the generated artwork. The books ship 1024px PNGs,
# which Chrome embeds whole: four illustrated editions came to 52MB. At 1024px
# a picture is 232dpi on a 112mm page, so nothing is lost by storing it as JPEG.
jpegs() {
  local src
  for src in images-v1 images-susu images-bismillah images-alhamdulillah images-khalaqa images-nabina; do
    [[ -d $src ]] || continue
    mkdir -p "input/img/$src"
    for png in "$src"/*.png; do
      local out="input/img/$src/$(basename "${png%.png}").jpg"
      [[ -f $out && $out -nt $png ]] && continue
      sips -s format jpeg -s formatOptions 88 "$png" --out "$out" >/dev/null
    done
  done
}
jpegs

# print/ holds finished PDFs only, split by which Arabic is on the page.
# The HTML Chrome renders from is scratch, so it goes in build/.
mkdir -p build print/arabic print/egyptian

one() {           # one <book> <qr> <suffix> [extra flags...]
  local book=$1 qr=$2 suffix=$3; shift 3
  local dest=print/arabic; case " $* " in *" --dialect eg "*) dest=print/egyptian ;; esac
  node tools/make-print.js "books/$book.html" "build/$book$suffix.html" \
       --url "$BASE/books/$book.html" --qr "input/qr/$qr" "$@"
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="$dest/$book$suffix.pdf" "file://$PWD/build/$book$suffix.html" 2>/dev/null
  printf '  %-50s %s\n' "$dest/$book$suffix.pdf" "$(du -h "$dest/$book$suffix.pdf" | cut -f1)"
}

for pair in "black-white-zoo qr-zoo.svg" "susu qr-susu.svg" \
            "bismillah qr-bismillah.svg" "alhamdulillah qr-alhamdulillah.svg" \
            "khalaqa qr-khalaqa.svg" "nabina qr-nabina.svg"; do
  set -- $pair; book=$1; qr=$2
  # Home printing only: 180mm square on card, laminated and glued. The
  # print-on-demand editions are the two volumes, built by build-volumes.sh.
  one "$book" "$qr" "-board" --board --art images
  one "$book" "$qr" "-board-eg" --board --art images --dialect eg
done
