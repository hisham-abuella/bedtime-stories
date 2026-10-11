#!/usr/bin/env bash
# Yaseen's Big Year in print, Egyptian Arabic only.
#
#   tools/build-yaseen-print.sh
#
#   print/egyptian/yaseen-board-eg.pdf          180mm square, printed at home
#   print/egyptian/yaseen-lulu-interior-eg.pdf  Lulu 8.5in square, perfect bound, 44 pages
#   print/egyptian/yaseen-lulu-cover-eg.pdf     its back + spine + front spread
#
# --long: 40-70 words a page, so long pages get a smaller picture and the type
# stays at 14pt English / 15pt Arabic or more. The Lulu edition needs 300ppi,
# so the approved 1024px pages are enlarged to 1400px rather than redrawn at
# 1536 (a new size is a new picture). The back cover is drawn at 1536.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
URL="https://hisham-abuella.github.io/bedtime-stories/books/yaseen.html"
QR=input/qr/qr-yaseen.svg
mkdir -p build print/egyptian input/img/images-yaseen input/img-hi/images-yaseen

for png in images-yaseen/*.png; do
  b=$(basename "${png%.png}")
  out=input/img/images-yaseen/$b.jpg
  [[ -f $out && $out -nt $png ]] || sips -s format jpeg -s formatOptions 88 "$png" --out "$out" >/dev/null
  hi=input/img-hi/images-yaseen/$b.jpg
  [[ -f $hi && $hi -nt $png ]] || sips -Z 1400 -s format jpeg -s formatOptions 90 "$png" --out "$hi" >/dev/null
done

one() {   # one <suffix> [flags...]
  local suffix=$1; shift
  node tools/make-print.js books/yaseen.html "build/yaseen$suffix.html" \
       --url "$URL" --qr "$QR" --art images --dialect eg --long "$@" >/dev/null
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="print/egyptian/yaseen$suffix.pdf" "file://$PWD/build/yaseen$suffix.html" 2>/dev/null
  printf '  %-46s %s\n' "print/egyptian/yaseen$suffix.pdf" "$(du -h "print/egyptian/yaseen$suffix.pdf" | cut -f1)"
}
one -board-eg          --board
one -lulu-interior-eg  --lulu
one -lulu-cover-eg     --lulu --cover --back-art input/img-hi/images-yaseen/print-back.jpg

# words all on the page, type at 14pt or more
python3 tools/check-print-text.py build/yaseen-board-eg.html print/egyptian/yaseen-board-eg.pdf
python3 tools/check-print-text.py build/yaseen-lulu-interior-eg.html print/egyptian/yaseen-lulu-interior-eg.pdf
