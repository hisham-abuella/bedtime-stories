#!/bin/zsh
# Loza the Cat: build books/loza.html from stories/loza.json.
# new-story.js writes a book for the repo root; the books live a directory
# down, so the paths move with it, and the name it is read to is Noah's.
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO"
node tools/new-story.js stories/loza.json
python3 - <<'PY'
s = open('loza.html', encoding='utf-8').read()
def swap(old, new):
    global s
    assert s.count(old) == 1, (old, s.count(old))
    s = s.replace(old, new)
swap('href="index.html" id="shelfLink"', 'href="../index.html" id="shelfLink"')
s = s.replace("'audio-loza/", "'../audio-loza/")
swap("pg.img = 'images-loza/'", "pg.img = '../images-loza/'")
swap("placeholder:'Yusuf'", "placeholder:'Noah'")
swap("placeholder:'يوسف'", "placeholder:'نوح'")
swap("'<span class=\"babyname\">Yusuf</span></p>'", "'<span class=\"babyname\">Noah</span></p>'")
swap("var fallback = t('dir') === 'rtl' ? 'يوسف' : 'Yusuf';", "var fallback = t('dir') === 'rtl' ? 'نوح' : 'Noah';")
open('books/loza.html', 'w', encoding='utf-8').write(s)
PY
rm loza.html
node tools/make-transcripts.js stories/loza.json
