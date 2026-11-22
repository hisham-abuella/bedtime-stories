#!/usr/bin/env python3
"""Regenerate the printed QR codes.

segno writes width/height but no viewBox, and without one the symbol renders
at its natural size and the page clips it into something that will not scan.
Every code here therefore gets a viewBox injected.

  uvx --with segno python tools/make-qr.py
"""
import re, sys
from pathlib import Path
import segno

sys.path.insert(0, str(Path(__file__).resolve().parent))
from siteurls import book_url, shelf_url   # tools/siteurls.py: the one place addresses live

OUT = Path(__file__).resolve().parent.parent / 'input' / 'qr'
CODES = {
    # the volume covers open the shelf (on the new site)
    'qr-shelf':         shelf_url(),
    # Noah's Animals and Colours cover keeps the old shelf it was printed with
    'qr-shelf-legacy':  shelf_url('legacy'),
    'qr-zoo':           book_url('black-white-zoo'),
    'qr-zoo-bw':        book_url('black-white-zoo') + '#bw',
    'qr-zoo-color':     book_url('black-white-zoo') + '#color',
    'qr-susu':          book_url('susu'),
    'qr-loza':          book_url('loza'),
    'qr-yaseen':        book_url('yaseen'),
    'qr-bismillah':     book_url('bismillah'),
    'qr-alhamdulillah': book_url('alhamdulillah'),
    'qr-khalaqa':       book_url('khalaqa'),
    'qr-nabina':        book_url('nabina'),
    # the back of Noah's First Words: his card on the shelf, which opens all four
    'qr-noah-first-words': shelf_url('legacy') + '#noah-first-words',
    # Noah's zoo: a code per chapter, as Yusuf's has
    'qr-noah-black-white-zoo-bw':    book_url('noah-black-white-zoo') + '#bw',
    'qr-noah-black-white-zoo-color': book_url('noah-black-white-zoo') + '#color',
}
# Every other book in books/ gets qr-<slug> without being listed: a new book
# has its code the moment it is built.
for page in sorted((OUT.parent.parent / 'books').glob('*.html')):
    url = book_url(page.stem)
    if url not in CODES.values():
        CODES[f'qr-{page.stem}'] = url
OUT.mkdir(parents=True, exist_ok=True)
for name, url in CODES.items():
    q = segno.make(url, error='q')          # quartile: survives a chewed corner
    svg = q.svg_inline(scale=10, border=2, dark='#111010')
    size = (q.symbol_size(scale=10, border=2))[0]
    svg = re.sub(r'<svg ', f'<svg viewBox="0 0 {size} {size}" '
                           'preserveAspectRatio="xMidYMid meet" ', svg, count=1)
    (OUT / f'{name}.svg').write_text(svg)
    print(f'  {name:20} {url}')
print(f'{len(CODES)} codes written to {OUT}')
