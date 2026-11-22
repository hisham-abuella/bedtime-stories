#!/usr/bin/env bash
# Put the committed books live, and prove it.
#
#   tools/publish.sh <slug> "<a phrase from the new text>"
#
# Pushes main, waits for GitHub Pages' "pages build and deployment" run
# (about two minutes), then reads the live page back and looks for the phrase,
# so the link handed over is known to show the new book, not the old one.
# Commit first; this refuses to publish uncommitted work.
set -euo pipefail
cd "$(dirname "$0")/.."
slug=${1:?usage: tools/publish.sh <slug> "<phrase from the new text>"}
phrase=${2:?usage: tools/publish.sh <slug> "<phrase from the new text>"}
# This push deploys GitHub Pages, so that copy is the one checked. The volumes'
# books are also on nostalgia-masry.com (tools/siteurls.py), deployed from the
# game site, and that is where their printed codes point.
URL=$(python3 tools/siteurls.py book "$slug" legacy)
PRINTED=$(python3 tools/siteurls.py book "$slug")

[[ -z $(git status --porcelain -- books stories "images-$slug" index.html) ]] \
  || { echo "publish: uncommitted changes in the book — commit first" >&2; git status --short -- books stories "images-$slug" index.html >&2; exit 1; }
git push -q origin main
sha=$(git rev-parse HEAD)
echo "pushed ${sha:0:7}; waiting for GitHub Pages…"

for _ in $(seq 1 60); do      # up to 10 minutes
  row=$(gh run list --workflow pages-build-deployment --limit 5 --json headSha,status,conclusion \
        -q ".[] | select(.headSha == \"$sha\") | .status + \" \" + .conclusion" | head -1)
  [[ $row == completed* ]] && break
  sleep 10
done
[[ $row == "completed success" ]] || { echo "publish: Pages deploy is '${row:-not started}' — check: gh run list" >&2; exit 1; }

if curl -fsS "$URL?nocache=$RANDOM" | grep -qF "$phrase"; then
  echo "live: $URL"
  echo "shelf: $(python3 tools/siteurls.py shelf legacy)"
  [[ $PRINTED == "$URL" ]] || echo "printed codes open $PRINTED — copy the book to the game site too"
  echo "(an old copy may be cached: Cmd+Shift+R, or close and reopen the tab on a phone)"
else
  echo "publish: deployed, but \"$phrase\" is not on $URL yet — the CDN can lag a minute; rerun the curl" >&2
  exit 1
fi
