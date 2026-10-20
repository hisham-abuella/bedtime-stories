#!/bin/zsh
# Loza the Cat: build books/loza.html from stories/loza.json, read to Noah.
# Fusha and Egyptian, short pages, and a drawn SVG set in stories/loza.art.js.
# Then the Yusuf / Noah dropdown, which build-book.py does not write.
set -e
python3 "$(dirname "$0")/build-book.py" loza --name Noah --name-ar نوح
python3 "$(dirname "$0")/build-noah-versions.py" >/dev/null
