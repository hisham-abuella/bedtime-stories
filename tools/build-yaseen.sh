#!/bin/zsh
# Yaseen's Big Year: build books/yaseen.html from stories/yaseen.json.
# new-story.js writes a book for the repo root; the books live a directory
# down, so the paths move with it. Yaseen's book is Egyptian Arabic only, so
# the فصحى/مصري switch goes and the Arabic button opens مصري directly.
# It has no drawn SVG pages: every picture comes from source/gen-yaseen.sh.
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO"
node tools/new-story.js stories/yaseen.json
python3 - <<'EOF'
import re
s = open('yaseen.html', encoding='utf-8').read()
def swap(old, new, count=1):
    global s
    assert s.count(old) == count, (old, s.count(old))
    s = s.replace(old, new)
swap('href="index.html" id="shelfLink"', 'href="../index.html" id="shelfLink"')
swap("'audio-yaseen/", "'../audio-yaseen/", 3)
swap("pg.img = 'images-yaseen/'", "pg.img = '../images-yaseen/'")
# his name, wherever the template says Yusuf
s = s.replace("placeholder:'Yusuf'", "placeholder:'Yaseen'").replace("placeholder:'يوسف'", "placeholder:'ياسين'")
swap("var fallback = t('dir') === 'rtl' ? 'يوسف' : 'Yusuf';", "var fallback = t('dir') === 'rtl' ? 'يَسّو' : 'Yaseen';")
s = s.replace('<span class="babyname">Yusuf</span>', '<span class="babyname">Yaseen</span>')
# Egyptian only
swap('<button type="button" data-lang="ar" aria-pressed="false" lang="ar">العربية</button>',
     '<button type="button" data-lang="ar" aria-pressed="false" lang="ar-EG">مصري</button>')
s = re.sub(r'<div class="seg lang" id="dialects".*?</div>', '<div id="dialects" hidden></div>', s, count=1, flags=re.S)
swap("var dialect = 'ar';", "var dialect = 'eg';")
swap("document.getElementById('dialects').hidden = lang === 'en';", "")
# A page here carries 40-70 words, five times the other books. Stacked under
# the picture in a 32ch column that runs far below the fold, so on a wide
# screen the picture and the words sit side by side.
s = s.replace('</style>', '''
  @media (min-width:900px){
    .book{width:min(1120px,100%)}
    .spread:not(.cover){display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);
      column-gap:34px;row-gap:16px;align-items:center;align-content:center}
    .spread:not(.cover) .stage{grid-row:1 / span 3;max-height:min(78vh,560px)}
    .spread:not(.cover) .words{max-width:44ch}
    .spread:not(.cover) .line{font-size:1.24rem;line-height:1.5}
  }
</style>''', 1)
# Only the pictures from the local model: no drawn SVG fallback, no Artwork switch
swap('<button class="pill" id="artBtn" type="button">', '<button class="pill" id="artBtn" type="button" hidden>')
swap("if (savedArt) useImages = savedArt === 'photo';", '')
swap(": page.art;", ": (page.art || '');")
swap('stage.innerHTML = page.art;', "stage.innerHTML = page.art || '';")
assert 'Yusuf' not in s and 'يوسف' not in s, 'a Yusuf survived'
open('books/yaseen.html', 'w', encoding='utf-8').write(s)
EOF
rm yaseen.html
echo "books/yaseen.html"
