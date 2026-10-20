#!/usr/bin/env python3
"""Noah's First Words: the four Muslim books as Noah's copies, for the web.

  python3 tools/build-noah-first-words.py

Bismillah, Alhamdulillah, Allah Made It and Our Prophet were written for
Yusuf, whose cat is Susu. Noah's copies, books/noah-<slug>.html, are the same
books with three differences:

  - read to Noah: every Yusuf is Noah
  - Loza in Susu's place, by name and in the picture (source/gen-loza.sh, fw-*)
  - Egyptian only, and pictures only (no drawn set: its cat is Susu-coloured)

The narration is Yusuf's except for the clips whose words changed. Those are
written to source/noah-<slug>-{en,eg}.json, recorded into audio-noah-<slug>/,
and the book plays them in place of the originals; every other page plays the
original clip. Rerun after any change to the originals.
"""
import json, os, re, sys

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(repo)

BOOKS = ['bismillah', 'alhamdulillah', 'khalaqa', 'nabina']
# Susu's pages, and the Loza picture that replaces each
LOZA_ART = {
    'bismillah':     {'bowl': 'fw-bowl'},
    'alhamdulillah': {'susu': 'fw-bed'},
    'khalaqa':       {'cat':  'fw-night'},
}
WORDS = [('Yusuf', 'Noah'), ('يوسف', 'نوح'), ('Susu', 'Loza'), ('سوسو', 'لوزة')]


def noah(s):
    for old, new in WORDS:
        s = s.replace(old, new)
    return s


for slug in BOOKS:
    s = open(f'books/{slug}.html', encoding='utf-8').read()

    def swap(old, new):
        global s
        if s.count(old) != 1:
            sys.exit(f'{slug}: expected one {old!r}, found {s.count(old)}')
        s = s.replace(old, new)

    s = noah(s)

    # Loza's pictures, after the loop that sets every page's picture
    loop_end = f"    pg.img = '../images-{slug}/' + IMG_V1[k][i] + '.png';\n  }});\n}});\n"
    over = ''.join(
        f"BOOK.{slug}.pages[IMG_V1.{slug}.indexOf('{old}')].img = '../images-loza/{new}.png';\n"
        for old, new in LOZA_ART.get(slug, {}).items()
        # until her picture is drawn, the page keeps the one it has
        if os.path.exists(f'images-loza/{new}.png'))
    swap(loop_end, loop_end + over)

    # Clips whose words changed, per language; the rest are the originals
    clips = {}
    for lang in ('en', 'eg'):
        src = json.load(open(f'source/{slug}-{lang}.json', encoding='utf-8'))
        changed = [dict(sl, transcript=noah(sl['transcript']))
                   for sl in src['slides'] if noah(sl['transcript']) != sl['transcript']]
        clips[lang] = [sl['id'] for sl in changed]
        out = dict(src, title=f"Noah {src['title']}", slides=changed)
        with open(f'source/noah-{slug}-{lang}.json', 'w', encoding='utf-8') as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
            f.write('\n')
    swap("player.src = AUDIO_DIR[ch][lang] + pages()[at].audio + '.mp3';",
         f"var NOAH_CLIPS = {json.dumps(clips)};\n"
         "  player.src = ((NOAH_CLIPS[lang] || []).indexOf(pages()[at].audio) > -1\n"
         f"      ? '../audio-noah-{slug}/' + lang + '/' : AUDIO_DIR[ch][lang]) + pages()[at].audio + '.mp3';")

    # Egyptian only (as build-book.py --eg-only)
    swap('<button type="button" data-lang="ar" aria-pressed="false" lang="ar">العربية</button>',
         '<button type="button" data-lang="ar" aria-pressed="false" lang="ar-EG">مصري</button>')
    s = re.sub(r'<div class="seg lang" id="dialects".*?</div>', '<div id="dialects" hidden></div>', s, count=1, flags=re.S)
    swap("var dialect = 'ar';", "var dialect = 'eg';")
    swap("document.getElementById('dialects').hidden = lang === 'en';", "")

    # pictures only (as build-book.py --no-svg)
    swap('<button class="pill" id="artBtn" type="button">', '<button class="pill" id="artBtn" type="button" hidden>')
    swap("if (savedArt) useImages = savedArt === 'photo';", '')

    open(f'books/noah-{slug}.html', 'w', encoding='utf-8').write(s)
    print(f'books/noah-{slug}.html   new clips  en: {" ".join(clips["en"]) or "-"}   eg: {" ".join(clips["eg"]) or "-"}')
