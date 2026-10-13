#!/usr/bin/env bash
# Build the two bound volumes for print-on-demand.
#
#   tools/build-volumes.sh
#
# Six separate 10-page books are below every binding Lulu offers except
# staples. Bound as two volumes they are 40 and 38 pages, which clears both
# the 32-page perfect-bound minimum and the 24-page hardcover one — so the
# books can be a real hardcover rather than a stapled pamphlet.
#
#   First Words          Bismillah · Alhamdulillah · Allah Made It · The Prophet Loved
#   Animals and Colours  Black & White · Fifteen Colours · Susu the Cat
#
# Each volume gets a cover of its own that lists what is inside; every book
# keeps its own cover page as a section divider.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BASE="https://hisham-abuella.github.io/bedtime-stories"
mkdir -p build print/arabic print/egyptian

ISLAMIC="books/bismillah.html,books/alhamdulillah.html,books/khalaqa.html,books/nabina.html"
ANIMALS="books/black-white-zoo.html,books/susu.html"

one() {   # one <slug> <books> <title-en> <title-ar> <suffix> [flags...]
  local slug=$1 books=$2 ten=$3 tar=$4 suffix=$5; shift 5
  local dest=print/arabic; case " $* " in *" --dialect eg "*) dest=print/egyptian ;; esac
  node tools/make-print.js "$books" "build/$slug$suffix.html" \
       --url "$BASE/" --lulu --art images --volume "$ten" --volume-ar "$tar" "$@" >/dev/null
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="$dest/$slug$suffix.pdf" "file://$PWD/build/$slug$suffix.html" 2>/dev/null
  printf '  %-54s %s\n' "$dest/$slug$suffix.pdf" "$(du -h "$dest/$slug$suffix.pdf" | cut -f1)"
}

# Animals and Colours has covers of its own: Susu with the zoo on the front,
# Susu waving goodbye on the back (source/gen-susu.sh, vol-front / vol-back).
SUSU_COVER="--front-art input/img-hi/images-susu/vol-front.jpg --back-art input/img-hi/images-susu/vol-back.jpg"
# First Words keeps Bismillah's sunrise house on the front; the back is the same
# house at night under a crescent moon, so the book opens on morning and closes
# on goodnight like each story in it (source/gen-muslim-books.sh, vol-back).
FIRST_COVER="--back-art input/img-hi/images-bismillah/vol-back.jpg"

for v in "vol-first-words|$ISLAMIC|First Words|أوّلُ الكلمات|$FIRST_COVER" \
         "vol-animals-colours|$ANIMALS|Animals and Colours|الحيوانات والألوان|$SUSU_COVER"; do
  IFS='|' read -r slug books ten tar art <<< "$v"
  read -r -a art <<< "$art"
  one "$slug" "$books" "$ten" "$tar" "-interior"    ${art[@]+"${art[@]}"}
  one "$slug" "$books" "$ten" "$tar" "-cover"       --cover ${art[@]+"${art[@]}"}
  one "$slug" "$books" "$ten" "$tar" "-interior-eg" --dialect eg ${art[@]+"${art[@]}"}
  one "$slug" "$books" "$ten" "$tar" "-cover-eg"    --cover --dialect eg ${art[@]+"${art[@]}"}
done
