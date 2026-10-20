#!/usr/bin/env python3
"""Build books/<slug>.html from stories/<slug>.json, for any book.

  python3 tools/build-book.py <slug> --name Noah --name-ar نوح
          [--fallback-ar يَسّو] [--eg-only] [--long] [--no-svg]

new-story.js fills the template for a book at the repo root, read to "Yusuf".
Every book lives a directory down and is read to its own child, so this:

  - runs new-story.js, then moves the result to books/<slug>.html with the
    shelf link, pictures and narration pointed one directory up
  - puts the child's name wherever the template says Yusuf (the name box,
    the fallback when the box is empty, the dedication, every babyname span);
    --fallback-ar sets a different Arabic fallback, e.g. a nickname
  - --eg-only: the Arabic button opens مصري and the فصحى/مصري switch goes
  - --long: 40-70 words a page, so wide screens put picture and words side
    by side, and phone type stays at 18px or more
  - --no-svg: pictures from the local model only, no drawn set, no switch
  - writes source/<slug>-{en,ar,eg}.json, the narration scripts, to match

Always rebuild a book through this (or its tools/build-<slug>.sh wrapper),
never new-story.js alone: a bare run undoes all of the above.
"""
import argparse, os, re, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument('slug')
ap.add_argument('--name', required=True)
ap.add_argument('--name-ar', required=True)
ap.add_argument('--fallback-ar')
ap.add_argument('--eg-only', action='store_true')
ap.add_argument('--long', action='store_true')
ap.add_argument('--no-svg', action='store_true')
o = ap.parse_args()

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(repo)
slug = o.slug
subprocess.run(['node', 'tools/new-story.js', f'stories/{slug}.json'], check=True)
s = open(f'{slug}.html', encoding='utf-8').read()

def swap(old, new):
    global s
    if s.count(old) != 1:
        sys.exit(f'build-book: expected one {old!r}, found {s.count(old)} — has the template changed?')
    s = s.replace(old, new)

# one directory down
swap('href="index.html" id="shelfLink"', 'href="../index.html" id="shelfLink"')
s = s.replace(f"'audio-{slug}/", f"'../audio-{slug}/")
swap(f"pg.img = 'images-{slug}/'", f"pg.img = '../images-{slug}/'")

# the child's name
swap("placeholder:'Yusuf'", f"placeholder:'{o.name}'")
swap("placeholder:'يوسف'", f"placeholder:'{o.name_ar}'")
swap("var fallback = t('dir') === 'rtl' ? 'يوسف' : 'Yusuf';",
     f"var fallback = t('dir') === 'rtl' ? '{o.fallback_ar or o.name_ar}' : '{o.name}';")
s = s.replace('<span class="babyname">Yusuf</span>', f'<span class="babyname">{o.name}</span>')

if o.eg_only:
    swap('<button type="button" data-lang="ar" aria-pressed="false" lang="ar">العربية</button>',
         '<button type="button" data-lang="ar" aria-pressed="false" lang="ar-EG">مصري</button>')
    s = re.sub(r'<div class="seg lang" id="dialects".*?</div>', '<div id="dialects" hidden></div>', s, count=1, flags=re.S)
    swap("var dialect = 'ar';", "var dialect = 'eg';")
    swap("document.getElementById('dialects').hidden = lang === 'en';", "")

if o.long:
    # A page here carries 40-70 words, five times the baby books. Stacked under
    # the picture in a 32ch column that runs far below the fold, so on a wide
    # screen the picture and the words sit side by side.
    s = s.replace('</style>', '''
  /* 18px is the floor for the story text on a phone */
  .spread:not(.cover) .line{font-size:clamp(1.15rem,4.4vw,1.45rem)}
  @media (min-width:900px){
    .book{width:min(1120px,100%)}
    .spread:not(.cover){display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);
      column-gap:34px;row-gap:16px;align-items:center;align-content:center}
    .spread:not(.cover) .stage{grid-row:1 / span 3;max-height:min(78vh,560px)}
    .spread:not(.cover) .words{max-width:44ch}
    .spread:not(.cover) .line{font-size:1.24rem;line-height:1.5}
  }
</style>''', 1)

if o.no_svg:
    swap('<button class="pill" id="artBtn" type="button">', '<button class="pill" id="artBtn" type="button" hidden>')
    swap("if (savedArt) useImages = savedArt === 'photo';", '')
    swap(": page.art;", ": (page.art || '');")
    swap('stage.innerHTML = page.art;', "stage.innerHTML = page.art || '';")

if 'Yusuf' in s or 'يوسف' in s:
    sys.exit('build-book: a Yusuf survived — the template has a new place for the name')
open(f'books/{slug}.html', 'w', encoding='utf-8').write(s)
os.remove(f'{slug}.html')
print(f'books/{slug}.html')
subprocess.run(['node', 'tools/make-transcripts.js', f'stories/{slug}.json'], check=True)
if o.eg_only and os.path.exists(f'source/{slug}-ar.json'):
    os.remove(f'source/{slug}-ar.json')     # no fusha narration for an Egyptian-only book
