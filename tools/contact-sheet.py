#!/usr/bin/env python3
"""Lay pictures out on one sheet, each with its name underneath, for review.

  python3 tools/contact-sheet.py <out.png> <picture> [picture …] [--cols 4] [--tile 300]
  python3 tools/contact-sheet.py build/yaseen-sheet.png art-hi/images-yaseen/*.png

Looking at 45 pages one at a time hides drift: a face that changed, hair a
shade lighter, a baby bigger than her brother. Side by side, they jump out.
Read the sheet, then open any suspicious page at full size — limbs especially
must be counted on the full picture, not on a 300px tile.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
def opt(name, default):
    if name in args:
        i = args.index(name); v = int(args[i + 1]); del args[i:i + 2]; return v
    return default
cols, tile = opt('--cols', 4), opt('--tile', 300)
if len(args) < 2:
    sys.exit(__doc__)
out, pics = args[0], args[1:]
cols = min(cols, len(pics))
rows = -(-len(pics) // cols)
label = 26
sheet = Image.new('RGB', (cols * tile, rows * (tile + label)), 'white')
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 16)
except OSError:
    font = ImageFont.load_default()
for i, p in enumerate(pics):
    x, y = (i % cols) * tile, (i // cols) * (tile + label)
    sheet.paste(Image.open(p).convert('RGB').resize((tile, tile)), (x, y))
    draw.text((x + 8, y + tile + 4), Path(p).stem, fill='black', font=font)
sheet.save(out)
print(f'{out}: {len(pics)} pictures')
