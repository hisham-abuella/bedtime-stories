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
  for src in images-v1 images-susu; do
    [[ -d $src ]] || continue
    mkdir -p "print/img/$src"
    for png in "$src"/*.png; do
      local out="print/img/$src/$(basename "${png%.png}").jpg"
      [[ -f $out && $out -nt $png ]] && continue
      sips -s format jpeg -s formatOptions 88 "$png" --out "$out" >/dev/null
    done
  done
}
jpegs

one() {           # one <book> <qr> <suffix> [extra flags...]
  local book=$1 qr=$2 suffix=$3; shift 3
  node tools/make-print.js "$book.html" "print/$book$suffix.html" \
       --url "$BASE/$book.html" --qr "print/$qr" "$@"
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="print/$book$suffix.pdf" "file://$PWD/print/$book$suffix.html" 2>/dev/null
  printf '  %-44s %s\n' "print/$book$suffix.pdf" "$(du -h "print/$book$suffix.pdf" | cut -f1)"
}

for pair in "black-white-zoo qr-zoo.svg" "susu qr-susu.svg"; do
  set -- $pair; book=$1; qr=$2
  one "$book" "$qr" "-print"
  one "$book" "$qr" "-print-illustrated" --art images
  one "$book" "$qr" "-board" --board
  one "$book" "$qr" "-board-illustrated" --board --art images
done
