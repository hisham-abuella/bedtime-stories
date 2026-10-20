#!/bin/zsh
# Yaseen's Big Year: build books/yaseen.html from stories/yaseen.json.
# Egyptian Arabic only, long pages, no drawn SVG pages: every picture comes
# from source/gen-yaseen.sh. His Arabic fallback is his nickname, يَسّو.
exec python3 "$(dirname "$0")/build-book.py" yaseen --name Yaseen --name-ar ياسين \
     --fallback-ar يَسّو --eg-only --long --no-svg
