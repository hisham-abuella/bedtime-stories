#!/usr/bin/env bash
# Build the Lulu print-on-demand editions: Small Square, saddle stitched.
#
#   tools/build-lulu.sh
#
# Two PDFs per book per artwork set, because Lulu takes the interior and the
# cover as separate uploads and the cover is a single back+front spread.
#
# Differences from the board edition, all of them required by Lulu's own
# Book Creation Guide and none of them cosmetic:
#   - 7.5in square trim with 0.125in bleed (they do not offer 180mm)
#   - 0.5in safety margin, not 8mm
#   - no crop marks and no folio ("do NOT include trim, bleed, or margin lines")
#   - the front cover lifted out of the interior into its own spread
#   - interiors padded with blanks to a multiple of four
#   - 1536px artwork, so every picture clears 300ppi
#
# Note this is NOT a board book. Lulu does not make them. Saddle stitch is
# stapled; for something a baby can chew, print the -board PDFs at home.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BASE="https://hisham-abuella.github.io/bedtime-stories"

# Print-weight JPEGs from the 1536px re-renders.
mkdir -p print/img-hi
missing=0
for src in images-v1 images-susu images-bismillah images-alhamdulillah images-khalaqa images-nabina; do
  [[ -d $src ]] || continue
  mkdir -p "print/img-hi/$src"
  for png in "$src"/*.png; do
    hi="art-hi/$src/$(basename "$png")"
    if [[ ! -f $hi ]]; then
      echo "  missing 1536px: $hi" >&2; missing=$((missing + 1)); continue
    fi
    out="print/img-hi/$src/$(basename "${png%.png}").jpg"
    [[ -f $out && $out -nt $hi ]] && continue
    # Lulu wants 300-600ppi, a ceiling as well as a floor. The 1536px master is
    # 387ppi in the 92mm stage but 629ppi in the 62mm cover box, so it is
    # resampled once to a width that lands inside the band for every box this
    # format uses: 62mm -> 574ppi, 96mm -> 370ppi.
    sips -Z 1400 -s format jpeg -s formatOptions 90 "$hi" --out "$out" >/dev/null
  done
done
if (( missing )); then
  echo >&2
  echo "$missing picture(s) have no 1536px version yet — run tools/regen-print-art.sh." >&2
  echo "Falling back to 1024px would silently ship pages under 300ppi, so stopping." >&2
  exit 1
fi

one() {           # one <book> <qr> <suffix> [extra flags...]
  local book=$1 qr=$2 suffix=$3; shift 3
  node tools/make-print.js "$book.html" "print/$book$suffix.html" \
       --url "$BASE/$book.html" --qr "print/$qr" --lulu "$@"
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="print/$book$suffix.pdf" "file://$PWD/print/$book$suffix.html" 2>/dev/null
  printf '  %-46s %s\n' "print/$book$suffix.pdf" "$(du -h "print/$book$suffix.pdf" | cut -f1)"
}

for pair in "black-white-zoo qr-zoo.svg" "susu qr-susu.svg" \
            "bismillah qr-bismillah.svg" "alhamdulillah qr-alhamdulillah.svg" \
            "khalaqa qr-khalaqa.svg" "nabina qr-nabina.svg"; do
  set -- $pair; book=$1; qr=$2
  one "$book" "$qr" "-lulu-interior"
  one "$book" "$qr" "-lulu-cover"              --cover
  one "$book" "$qr" "-lulu-interior-illustrated" --art images
  one "$book" "$qr" "-lulu-cover-illustrated"  --cover --art images
done
