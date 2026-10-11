#!/usr/bin/env bash
# Check every Lulu PDF against Lulu's published requirements.
#
#   tools/check-lulu.sh
#
# A PDF that is wrong in any of these ways still opens and still looks right on
# screen, which is exactly why this is a script and not an eyeball. Each check
# is one line from the Book Creation Guide.
set -uo pipefail
cd "$(dirname "$0")/.."

# 8.75in square: 8.5in trim + 0.125in bleed, matching Lulu's own Square
# interior template exactly (630 x 630 pts).
INTERIOR_W=630
COVER_H=630
# The cover is two trims plus the spine, and the spine depends on the page
# count: Lulu's spine(in) = pages/444 + 0.06. Their generic template ships the
# 32-page spine, so it is computed here from the interior instead.
TOL=2                         # pts; Chrome rounds, Lulu trims to 0.125in (9pt)
fail=0
note() { printf '    %-18s %s\n' "$1" "$2"; }
bad()  { fail=$((fail + 1)); printf '    %-18s \033[31m%s\033[0m\n' "$1" "$2"; }

# Noah's set sits a level deeper, in print/noah/<arabic|egyptian>/
shopt -s nullglob
vols=(print/*/vol-*.pdf print/*/*/vol-*.pdf print/*/*-lulu-*.pdf)   # single-book Lulu editions too
(( ${#vols[@]} )) || { echo "no volume PDFs built yet — run tools/build-volumes.sh"; exit 1; }
for f in "${vols[@]}"; do
  echo "$(basename "$f")"
  info=$(pdfinfo "$f")
  pages=$(awk '/^Pages:/{print $2}' <<<"$info")
  size=$(sed -n 's/^Page size: *\([0-9.]* x [0-9.]*\).*/\1/p' <<<"$info" | head -1)

  # 1. trim + bleed, checked numerically
  w=${size% x *}; h=${size#* x }
  if [[ $f == *-cover* ]]; then
    ipages=$(pdfinfo "${f/-cover/-interior}" 2>/dev/null | awk '/^Pages:/{print $2}')
    [[ -z $ipages ]] && ipages=40
    want=$(python3 -c "print((2*8.5 + $ipages/444 + 0.06 + 0.25) * 72)")
    label="cover for $ipages pages"
  else
    want=$INTERIOR_W; label="interior"
  fi
  ok=$(python3 -c "print(1 if abs($w - $want) <= $TOL and abs($h - $COVER_H) <= $TOL else 0)")
  if [[ $ok == 1 ]]; then note "size" "$size pts ($label)"
  else bad "size" "$size pts (want ${want} x ${COVER_H}, $label)"; fi

  # 2. page count: cover is one spread; interiors fold in fours, 4-48 saddle stitch
  if [[ $f == *-cover* ]]; then
    [[ $pages == 1 ]] && note "pages" "1 spread" || bad "pages" "$pages (a cover is one page)"
  else
    if (( pages % 4 )); then bad "pages" "$pages (not a multiple of 4)"
    elif (( pages < 32 )); then bad "pages" "$pages (perfect bound needs 32+)"
    elif (( pages > 800 )); then bad "pages" "$pages (perfect bound tops out at 800)"
    else note "pages" "$pages"; fi
  fi

  # 3. images 300-600ppi
  imgs=$(pdfimages -list "$f" 2>/dev/null | awk 'NR>2 && $13!=""{print $13}')
  if [[ -z $imgs ]]; then
    note "images" "none (vector artwork)"
  else
    lo=$(sort -n <<<"$imgs" | head -1); hi=$(sort -n <<<"$imgs" | tail -1)
    n=$(wc -l <<<"$imgs" | tr -d ' ')
    under=$(awk '$1<300' <<<"$imgs" | wc -l | tr -d ' ')
    over=$(awk '$1>600' <<<"$imgs" | wc -l | tr -d ' ')
    if (( under )); then bad "images" "$under of $n under 300ppi (lowest ${lo})"
    elif (( over )); then bad "images" "$over of $n over 600ppi (highest ${hi})"
    else note "images" "$n at ${lo}-${hi}ppi"; fi
  fi

  # 4. every font embedded
  notemb=$(pdffonts "$f" 2>/dev/null | awk 'NR>2 && $(NF-3)=="no"' | wc -l | tr -d ' ')
  (( notemb )) && bad "fonts" "$notemb not embedded" || note "fonts" "all embedded"

  # 5. no password protection
  grep -q '^Encrypted: *no' <<<"$info" && note "encryption" "none" || bad "encryption" "file is protected"

  # 6. no trim, bleed or margin lines — checked in the source, where they'd come from
  src=build/$(basename "${f%.pdf}").html
  if [[ -f $src ]]; then
    marks=$(grep -c 'class="mark\|class="folio"' "$src" || true)
    (( marks )) && bad "marks" "$marks crop/folio marks present" || note "marks" "none"
  fi
done

echo
if (( fail )); then echo "$fail check(s) failed"; exit 1; else echo "all checks passed"; fi
