"""Decode every QR in every print PDF and check it opens the right story.

A QR that renders still looks like a QR when it is clipped, wrong, or stale.
The only proof is reading it back out of the finished PDF, which is what this
does: rasterise each page, decode, compare against the URL that page should
carry.

  uvx --with zxing-cpp --with pillow python tools/check-qr.py [<slug>]

With a slug, only that book's PDFs (and volumes that hold it) are read.
"""
import subprocess, sys, glob, os, re, tempfile
from pathlib import Path
import zxingcpp
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
BASE = 'https://hisham-abuella.github.io/bedtime-stories'
TMP = Path(tempfile.mkdtemp(prefix='qrpages-'))

# what each book's codes are allowed to point at
ALLOWED = {
    'black-white-zoo': {f'{BASE}/books/black-white-zoo.html', f'{BASE}/books/black-white-zoo.html#bw',
                        f'{BASE}/books/black-white-zoo.html#color'},
    'susu':          {f'{BASE}/books/susu.html'},
    'loza':          {f'{BASE}/books/loza.html'},
    'bismillah':     {f'{BASE}/books/bismillah.html'},
    'alhamdulillah': {f'{BASE}/books/alhamdulillah.html'},
    'khalaqa':       {f'{BASE}/books/khalaqa.html'},
    'nabina':        {f'{BASE}/books/nabina.html'},
    'noah-black-white-zoo': {f'{BASE}/books/noah-black-white-zoo.html', f'{BASE}/books/noah-black-white-zoo.html#bw',
                             f'{BASE}/books/noah-black-white-zoo.html#color'},
}
# any other book in books/ may point only at itself
for page in (REPO / 'books').glob('*.html'):
    ALLOWED.setdefault(page.stem, {f'{BASE}/books/{page.name}'})

# A bound volume carries one code per chapter, so its allowed set is the union
# of the books inside it.
VOLUMES = {
    'vol-first-words': ['bismillah', 'alhamdulillah', 'khalaqa', 'nabina'],
    'vol-animals-colours': ['black-white-zoo', 'susu'],
    # Noah's copies: his own First Words, and Loza in Susu's place
    'vol-noah-first-words': ['noah-bismillah', 'noah-alhamdulillah', 'noah-khalaqa', 'noah-nabina'],
    'vol-noah-animals-colours': ['noah-black-white-zoo', 'loza'],
}
def book_of(name):
    for v, books in VOLUMES.items():
        if name.startswith(v):
            return v
    for b in sorted(ALLOWED, key=len, reverse=True):
        if name.startswith(b):
            return b
    return None

rows, bad, total_codes = [], [], 0
pdfs = sorted(glob.glob(str(REPO / 'print' / '**' / '*.pdf'), recursive=True))
only = sys.argv[1] if len(sys.argv) > 1 else None
if only:
    pdfs = [p for p in pdfs if book_of(Path(p).stem) == only
            or only in VOLUMES.get(book_of(Path(p).stem), [])]
for pdf in pdfs:
    name = Path(pdf).stem
    book = book_of(name)
    if not book:
        bad.append((name, 'cannot tell which book this is')); continue
    for f in TMP.glob('*.png'):
        f.unlink()
    subprocess.run(['pdftoppm', '-r', '200', '-png', pdf, str(TMP / 'p')],
                   check=True, capture_output=True)
    found = []
    for img in sorted(TMP.glob('*.png')):
        res = zxingcpp.read_barcodes(Image.open(img))
        for r in res:
            if r.format == zxingcpp.BarcodeFormat.QRCode:
                found.append((img.stem, r.text))
    total_codes += len(found)
    # How many codes this file should carry. A Lulu interior has no front
    # cover -- it moved to the cover spread -- so only the zoo, whose second
    # chapter opens with its own cover inside the book, has one there.
    if book in VOLUMES:
        # every chapter cover is inside the volume; the volume's own cover is
        # a separate file and carries one code
        chapters = {'black-white-zoo': 2, 'noah-black-white-zoo': 2}
        inside = sum(chapters.get(b, 1) for b in VOLUMES[book])
        want = 1 if name.endswith('-cover') or name.endswith('-cover-eg') else inside
    elif '-lulu-interior' in name:
        want = 1 if book == 'black-white-zoo' else 0
    elif '-lulu-cover' in name:
        want = 1
    else:
        want = 2 if book == 'black-white-zoo' else 1   # book cover + chapter cover
    if len(found) != want:
        bad.append((name, f'expected {want} QR, found {len(found)}'))
    for page, text in found:
        allowed = {f'{BASE}/'}          # a volume cover opens the shelf
        if book == 'vol-noah-first-words':
            allowed = {f'{BASE}/#noah-first-words'}   # Noah's card on it
        for b in VOLUMES.get(book, [book]):
            allowed |= ALLOWED[b]
        if text not in allowed:
            bad.append((name, f'{page}: {text!r} is not a {book} link'))
    rows.append((name, len(found), sorted({t for _, t in found})))

print(f'{len(pdfs)} PDFs, {total_codes} QR codes decoded\n')
for name, n, urls in rows:
    mark = ' ' if n else '!'
    print(f'{mark} {name:52} {n} -> {", ".join(u.replace(BASE, "") or "/" for u in urls)}')
print()
if bad:
    print(f'{len(bad)} PROBLEM(S):')
    for n, m in bad:
        print(f'  {n}: {m}')
    sys.exit(1)
print('every QR decodes, and every one points at its own story')
