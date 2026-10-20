#!/bin/zsh
# Loza the Cat: build books/loza.html from stories/loza.json, read to Noah.
# Fusha and Egyptian, short pages, and a drawn SVG set in stories/loza.art.js.
exec python3 "$(dirname "$0")/build-book.py" loza --name Noah --name-ar نوح
