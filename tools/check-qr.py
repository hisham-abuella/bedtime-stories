"""Decode every QR in every print PDF and check it opens the right story.

A QR that renders still looks like a QR when it is clipped, wrong, or stale.
The only proof is reading it back out of the finished PDF, which is what this
does: rasterise each page, decode, compare against the URL that page should
carry.
"""
import subprocess, sys, glob, os, re
from pathlib import Path
import zxingcpp
from PIL import Image

REPO = Path('/Users/hishamabuella/Work/bedtime-stories')
BASE = 'https://hisham-abuella.github.io/bedtime-stories'
TMP = Path('/private/tmp/claude-501/-Users-hishamabuella-Work/00b1ad39-acac-4ee0-8191-40b45b61f32e/scratchpad/qrpages')
TMP.mkdir(exist_ok=True)

# what each book's codes are allowed to point at
ALLOWED = {
    'black-white-zoo': {f'{BASE}/books/black-white-zoo.html', f'{BASE}/books/black-white-zoo.html#bw',
                        f'{BASE}/books/black-white-zoo.html#color'},
    'susu':          {f'{BASE}/books/susu.html'},
    'bismillah':     {f'{BASE}/books/bismillah.html'},
    'alhamdulillah': {f'{BASE}/books/alhamdulillah.html'},
    'khalaqa':       {f'{BASE}/books/khalaqa.html'},
    'nabina':        {f'{BASE}/books/nabina.html'},
}

def book_of(name):
    for b in sorted(ALLOWED, key=len, reverse=True):
        if name.startswith(b):
            return b
    return None

rows, bad, total_codes = [], [], 0
pdfs = sorted(glob.glob(str(REPO / 'print' / '*' / '*.pdf')))
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
    if '-lulu-interior' in name:
        want = 1 if book == 'black-white-zoo' else 0
    elif '-lulu-cover' in name:
        want = 1
    else:
        want = 2 if book == 'black-white-zoo' else 1   # book cover + chapter cover
    if len(found) != want:
        bad.append((name, f'expected {want} QR, found {len(found)}'))
    for page, text in found:
        if text not in ALLOWED[book]:
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
