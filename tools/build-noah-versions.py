#!/usr/bin/env python3
"""Noah's versions of Yusuf's books, and the Yusuf / Noah switch between them.

  python3 tools/build-noah-versions.py

The four First Words books and the Black and White Zoo were written for
Yusuf, whose cat is Susu. Noah's copies, books/noah-<slug>.html, are the same
books with these differences:

  - read to Noah: every Yusuf is Noah
  - Loza in Susu's place, by name and, in First Words, in the picture
    (source/gen-loza.sh, fw-*)
  - Egyptian only; First Words also pictures only (its drawn cat is Susu-coloured)

The narration is Yusuf's except for the clips whose words changed. Those are
written to source/noah-<slug>-{en,eg}.json, recorded into audio-noah-<slug>/,
and the book plays them in place of the originals; every other page plays the
original clip.

Every one of these books, and Susu's and Loza's, has a "Read it to" dropdown
(Yusuf / Noah) in place of the name box: picking the other child opens that
child's version, in the language being read. Susu's story is Yusuf's and
Loza's is Noah's, so between those two the dropdown opens the other cat.

Rerun after any change to the originals, and after rebuilding loza.html
(build-book.py writes a plain name box).
"""
import json, os, re, sys

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(repo)

# slug: narration scripts (source/<name>-<lang>.json), Loza's pictures in
# place of Susu's, and whether the drawn set goes
BOOKS = {
    'bismillah':       {'scripts': ['bismillah'],     'loza': {'bowl': 'fw-bowl'}, 'no_svg': True},
    'alhamdulillah':   {'scripts': ['alhamdulillah'], 'loza': {'susu': 'fw-bed'},  'no_svg': True},
    'khalaqa':         {'scripts': ['khalaqa'],       'loza': {'cat':  'fw-night'}, 'no_svg': True},
    'nabina':          {'scripts': ['nabina'],        'loza': {},                  'no_svg': True},
    # the zoo's two chapters have a script each; its pictures have no cat of Susu's
    'black-white-zoo': {'scripts': ['story', 'colors'], 'loza': {},                'no_svg': False},
}
WORDS = [('Yusuf', 'Noah'), ('يوسف', 'نوح'), ('Susu', 'Loza'), ('سوسو', 'لوزة')]


def noah(s):
    for old, new in WORDS:
        s = s.replace(old, new)
    return s


def readers(yusuf, noah_file, current):
    # Who the book is read to: a dropdown in place of the name box. Each child
    # is a version of the book, so picking the other one opens the other file,
    # in the language being read.
    return ("var READER = '" + current + "', READERS = ["
            f"{{file:'{yusuf}', en:'Yusuf', ar:'يوسف'}}, "
            f"{{file:'{noah_file}', en:'Noah', ar:'نوح'}}];\n")


def add_switch(s, slug, reader_line):
    """Put the Yusuf / Noah dropdown in place of a book's name box."""
    def swap(old, new):
        nonlocal s
        if s.count(old) != 1:
            sys.exit(f'{slug}: expected one {old!r}, found {s.count(old)}')
        s = s.replace(old, new)

    key = re.search(r"localStorage\.getItem\('([a-z-]+)-name'\)", s).group(1)
    swap("var ch = '", reader_line + "var ch = '")
    swap('''    html += '<div class="namer"><label for="babyname">' + ui.readTo + '</label>' +
      '<input id="babyname" type="text" autocomplete="off" maxlength="18" placeholder="' + ui.placeholder + '" value="' +
      babyName.replace(/"/g, '&quot;') + '"></div>';''',
         '''    html += '<div class="namer"><label for="reader">' + ui.readTo + '</label><select id="reader">' +
      READERS.map(function (r) {
        return '<option value="' + r.file + '"' + (r.file === READER ? ' selected' : '') + '>' +
          (t('dir') === 'rtl' ? r.ar : r.en) + '</option>';
      }).join('') + '</select></div>';''')
    swap(f'''  var input = document.getElementById('babyname');
  if (input) {{
    input.addEventListener('input', function () {{
      babyName = input.value;
      applyName();
      try {{ localStorage.setItem('{key}-name', babyName.trim()); }} catch (e) {{}}
    }});
  }}''', '''  var reader = document.getElementById('reader');
  if (reader) {
    reader.addEventListener('change', function () {
      // a book with chapters (the zoo) reopens on the same one
      location.href = reader.value + '?lang=' + lang + (Object.keys(BOOK).length > 1 ? '#' + ch : '');
    });
  }''')
    # a name typed in the old box would override the child picked here
    swap(f'''  var saved = localStorage.getItem('{key}-name');
  if (saved) babyName = saved;
''', '')
    swap('  .namer input{', '  .namer input,.namer select{')
    swap('  .namer input:focus-visible{', '  .namer input:focus-visible,.namer select:focus-visible{')
    # arriving from the other child's version: carry on in the same language
    end = s.rindex('</script>')
    s = s[:end] + '''(function () {
  var q = (location.search.match(/[?&]lang=(en|ar|eg)/) || [])[1];
  if (!q || q === 'en') return;
  if (document.querySelector('#dialects [data-lang="' + q + '"]')) dialect = q;
  document.querySelector('#langs [data-lang="ar"]').click();
})();
''' + s[end:]
    return s


def switched(slug, reader_line):
    """books/<slug>.html with the dropdown, added once."""
    s = open(f'books/{slug}.html', encoding='utf-8').read()
    if 'var READER = ' not in s:
        s = add_switch(s, slug, reader_line)
        open(f'books/{slug}.html', 'w', encoding='utf-8').write(s)
    return s


# the true stories: one cat each, so the other child's version is the other cat
for cat in ('susu', 'loza'):
    switched(cat, readers('susu.html', 'loza.html', f'{cat}.html'))
    print(f'books/{cat}.html        Read it to: Yusuf -> susu.html, Noah -> loza.html')

for slug, book in BOOKS.items():
    s = switched(slug, readers(f'{slug}.html', f'noah-{slug}.html', f'{slug}.html'))

    def swap(old, new):
        global s
        if s.count(old) != 1:
            sys.exit(f'{slug}: expected one {old!r}, found {s.count(old)}')
        s = s.replace(old, new)

    s = noah(s)
    # noah() turned the dropdown's Yusuf into a second Noah: put it back
    s = re.sub(r"var READER = .*\n",
               lambda m: readers(f'{slug}.html', f'noah-{slug}.html', f'noah-{slug}.html'), s, count=1)
    # the zoo's link to Susu's book goes to Loza's
    s = s.replace('href="susu.html"', 'href="loza.html"')

    # Loza's pictures, after the loop that sets every page's picture
    if book['loza']:
        loop_end = f"    pg.img = '../images-{slug}/' + IMG_V1[k][i] + '.png';\n  }});\n}});\n"
        over = ''.join(
            f"BOOK.{slug}.pages[IMG_V1.{slug}.indexOf('{old}')].img = '../images-loza/{new}.png';\n"
            for old, new in book['loza'].items()
            # until her picture is drawn, the page keeps the one it has
            if os.path.exists(f'images-loza/{new}.png'))
        swap(loop_end, loop_end + over)

    # Clips whose words changed, per language; the rest are the originals
    clips = {}
    for lang in ('en', 'eg'):
        changed, title = [], None
        for name in book['scripts']:
            src = json.load(open(f'source/{name}-{lang}.json', encoding='utf-8'))
            title = title or src['title']
            changed += [dict(sl, transcript=noah(sl['transcript']))
                        for sl in src['slides'] if noah(sl['transcript']) != sl['transcript']]
        clips[lang] = [sl['id'] for sl in changed]
        out = dict(src, title=f'Noah {title}', slides=changed)
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
    if book['no_svg']:
        swap('<button class="pill" id="artBtn" type="button">', '<button class="pill" id="artBtn" type="button" hidden>')
        swap("if (savedArt) useImages = savedArt === 'photo';", '')

    open(f'books/noah-{slug}.html', 'w', encoding='utf-8').write(s)
    print(f'books/noah-{slug}.html   new clips  en: {" ".join(clips["en"]) or "-"}   eg: {" ".join(clips["eg"]) or "-"}')
