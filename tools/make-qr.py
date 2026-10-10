#!/usr/bin/env python3
"""Regenerate the printed QR codes.

segno writes width/height but no viewBox, and without one the symbol renders
at its natural size and the page clips it into something that will not scan.
Every code here therefore gets a viewBox injected.
"""
import re, sys
from pathlib import Path
import segno

BASE = 'https://hisham-abuella.github.io/bedtime-stories'
OUT = Path(__file__).resolve().parent.parent / 'input' / 'qr'
CODES = {
    'qr-zoo':           f'{BASE}/books/black-white-zoo.html',
    'qr-zoo-bw':        f'{BASE}/books/black-white-zoo.html#bw',
    'qr-zoo-color':     f'{BASE}/books/black-white-zoo.html#color',
    'qr-susu':          f'{BASE}/books/susu.html',
    'qr-bismillah':     f'{BASE}/books/bismillah.html',
    'qr-alhamdulillah': f'{BASE}/books/alhamdulillah.html',
    'qr-khalaqa':       f'{BASE}/books/khalaqa.html',
    'qr-nabina':        f'{BASE}/books/nabina.html',
}
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
