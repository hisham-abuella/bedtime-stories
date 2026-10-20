#!/usr/bin/env bash
# Print PDFs for one book, checked, from books/<slug>.html.
#
#   tools/print-book.sh <slug> [--eg-only] [--long] [--lulu] [--back-art FILE]
#                              [--name Noah --name-ar نوح]
#
#   print/egyptian/<slug>-board-eg.pdf           180mm square, printed at home on card
#   print/arabic/<slug>-board.pdf                the same with fusha (not with --eg-only)
#   print/…/<slug>-lulu-interior[-eg].pdf        --lulu: Lulu 8.5in square, perfect bound
#   print/…/<slug>-lulu-cover[-eg].pdf           --lulu: back + spine + front, one spread
#
# --long      40-70 words a page: a smaller picture, so type stays 14pt+ / 15pt+
# --back-art  a picture for the back cover (draw one at 1536, e.g. waving goodbye)
# --name      fix the child's name on paper (the screen book asks for it)
#
# Pictures are always high resolution. Every page is drawn once at 1536px into
# art-hi/images-<slug>/ (tools/web-art.sh shrinks the same pictures for the
# web), and both editions print from 1400px JPEGs made from those masters:
# input/img-hi/ for Lulu and input/img/ for the board book. art-hi/ is not
# committed, so on another machine the committed input/img-hi/ JPEGs are used.
# A 1024px picture is never enlarged: with no hi-res copy, this stops.
#
# The QR code is input/qr/qr-<slug>.svg; tools/make-qr.py makes it for every
# book in books/. Every PDF is then checked: words not clipped, type not too
# small (check-print-text.py), Lulu's rules (check-lulu.sh), and the QR codes
# decode to this book (check-qr.py).
set -euo pipefail
cd "$(dirname "$0")/.."

slug=${1:?usage: tools/print-book.sh <slug> [--eg-only] [--long] [--lulu] [--back-art FILE] [--name N --name-ar N]}
shift
eg_only=0 lulu=0 back='' extra=()
while (( $# )); do
  case $1 in
    --eg-only) eg_only=1 ;;
    --lulu)    lulu=1 ;;
    --long)    extra+=(--long) ;;
    --back-art) back=$2; shift ;;
    --name|--name-ar) extra+=("$1" "$2"); shift ;;
    *) echo "print-book: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
URL="https://hisham-abuella.github.io/bedtime-stories/books/$slug.html"
QR=input/qr/qr-$slug.svg
[[ -f books/$slug.html ]] || { echo "no books/$slug.html — build the book first" >&2; exit 1; }
[[ -f $QR ]] || uvx --with segno python tools/make-qr.py >/dev/null
if (( lulu )); then
  # Lulu's perfect binding (the hardcover-like one) needs 32 pages. A short
  # book is bound with others as a volume instead (tools/build-volumes.sh,
  # tools/build-noah.sh), or printed as the board edition only.
  pages=$(node -e "console.log(require('./stories/$slug.json').pages.length)")
  if (( pages < 32 )); then
    echo "print-book: $slug has $pages pages; Lulu perfect binding needs 32+." >&2
    echo "  Bind it with other books as a volume, or drop --lulu for the board edition." >&2
    exit 1
  fi
fi
mkdir -p build print/arabic print/egyptian "input/img/images-$slug" "input/img-hi/images-$slug"

missing=0
for png in "images-$slug"/*.png; do
  b=$(basename "${png%.png}")
  master=art-hi/images-$slug/$b.png
  hi=input/img-hi/images-$slug/$b.jpg
  out=input/img/images-$slug/$b.jpg
  if [[ -f $master ]]; then
    [[ -f $hi && $hi -nt $master ]]   || sips -Z 1400 -s format jpeg -s formatOptions 90 "$master" --out "$hi"  >/dev/null
    [[ -f $out && $out -nt $master ]] || sips -Z 1400 -s format jpeg -s formatOptions 88 "$master" --out "$out" >/dev/null
  elif [[ -f $hi ]]; then
    [[ -f $out && $out -nt $hi ]] || cp "$hi" "$out"
  else
    echo "  no high-resolution copy of $b: $master" >&2; missing=$((missing + 1))
  fi
done
if (( missing )); then
  echo "draw them at 1536px first: DEST=\$PWD/art-hi/images-$slug SIZE=1536 zsh source/gen-$slug.sh" >&2
  exit 1
fi

made=()
one() {   # one <dest-dir> <file-stem> [flags...]
  local dest=$1 stem=$2; shift 2
  node tools/make-print.js "books/$slug.html" "build/$stem.html" \
       --url "$URL" --qr "$QR" --art images ${extra[@]+"${extra[@]}"} "$@" >/dev/null
  "$CHROME" --headless --no-pdf-header-footer \
       --print-to-pdf="$dest/$stem.pdf" "file://$PWD/build/$stem.html" 2>/dev/null
  printf '  %-50s %s\n' "$dest/$stem.pdf" "$(du -h "$dest/$stem.pdf" | cut -f1)"
  made+=("$stem|$dest")
}

dialects=(eg); (( eg_only )) || dialects=(eg ar)
for d in "${dialects[@]}"; do
  if [[ $d == eg ]]; then dest=print/egyptian sfx=-eg dflag=(--dialect eg); else dest=print/arabic sfx='' dflag=(); fi
  one "$dest" "$slug-board$sfx" --board ${dflag[@]+"${dflag[@]}"}
  if (( lulu )); then
    one "$dest" "$slug-lulu-interior$sfx" --lulu ${dflag[@]+"${dflag[@]}"}
    one "$dest" "$slug-lulu-cover$sfx" --lulu --cover ${back:+--back-art "$back"} ${dflag[@]+"${dflag[@]}"}
  fi
done

echo
echo "checking words and type size…"
fail=0
for m in "${made[@]}"; do
  stem=${m%%|*} dest=${m#*|}
  [[ $stem == *-cover* ]] && continue
  python3 tools/check-print-text.py "build/$stem.html" "$dest/$stem.pdf" || fail=1
done
if (( lulu )); then
  echo; echo "checking Lulu's rules…"
  bash tools/check-lulu.sh | tail -1 || fail=1
fi
echo; echo "checking QR codes…"
uvx --with zxing-cpp --with pillow python tools/check-qr.py "$slug" | tail -1 || fail=1

(( fail )) && { echo; echo "print-book: a check failed — see above. Arabic words with a shadda can show as 'clipped' falsely: render that page and look." >&2; exit 1; }
echo; echo "all checks passed"
