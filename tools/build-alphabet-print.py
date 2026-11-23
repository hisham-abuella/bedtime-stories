#!/usr/bin/env python3
"""Print editions of the two alphabet books, from stories/alphabet.json.

  python3 tools/build-alphabet-print.py            # both books, all editions
  python3 tools/build-alphabet-print.py abc        # one book

  print/arabic/...   not used (the alphabet is Egyptian only)
  print/egyptian/huroof-board-eg.pdf, huroof-lulu-interior-eg.pdf, huroof-lulu-cover-eg.pdf
  print/alphabet/abc-board.pdf,       abc-lulu-interior.pdf,       abc-lulu-cover.pdf

Board edition: 180mm square + 3mm bleed, crop marks, for card at home.
Lulu edition: 8.5in square, 0.125in bleed, 0.5in safety, perfect bound, 32 pages
(tools/check-lulu.sh reads these). The cover is one back + spine + front spread.
Pictures print from art-hi/images-alphabet (1536px masters) as 1400px JPEGs, so
every picture lands between 300 and 600ppi. The story-book printer
(tools/make-print.js) reads stories, not letter grids, hence this script.
"""
import html, json, subprocess, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'tools'))
from siteurls import book_url
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
IN = 25.4
TINTS = ['#F3D9C4', '#DDE8D2', '#D6E3EC', '#F1E2B8', '#E9D5E3', '#D9E6E1', '#F0D4CC']
spec = json.loads((REPO / 'stories/alphabet.json').read_text())
E = html.escape

CFG = {
    'abc': dict(book='en', dest='print/alphabet', sfx='', ar=False,
                listen='Listen to every letter', credit_label='Credits',
                made='Made with love'),
    'huroof': dict(book='eg', dest='print/egyptian', sfx='-eg', ar=True,
                   listen='اسمع كل حرف', credit_label='',
                   made='اتعمل بحب'),
}
CREDIT = 'Lullaby on the website: “Lullaby (Johannes Brahms)” by BrunoXe, CC BY 3.0 (Jamendo).'


def qr_svg(slug):
    s = (REPO / f'input/qr/qr-{slug}.svg').read_text()
    return s[s.index('<svg'):]


def pictures(slug_names):
    """1400px JPEG per picture, made once from the 1536px master."""
    out = REPO / 'input/img-hi/images-alphabet'
    out.mkdir(parents=True, exist_ok=True)
    for n in sorted(slug_names):
        m = REPO / f'art-hi/images-alphabet/{n}.png'
        o = out / f'{n}.jpg'
        if o.exists() and (not m.exists() or o.stat().st_mtime >= m.stat().st_mtime):
            continue
        if not m.exists():
            sys.exit(f'no 1536px master for {n}: {m}')
        subprocess.run(['sips', '-Z', '1400', '-s', 'format', 'jpeg', '-s', 'formatOptions', '90',
                        str(m), '--out', str(o)], check=True, capture_output=True)


def small(names, px):
    """Smaller copies for the letter grids, so tiles stay under Lulu's 600ppi."""
    out = REPO / f'input/img-hi/images-alphabet/grid{px}'
    out.mkdir(parents=True, exist_ok=True)
    for n in names:
        src = REPO / f'input/img-hi/images-alphabet/{n}.jpg'
        o = out / f'{n}.jpg'
        if not (o.exists() and o.stat().st_mtime >= src.stat().st_mtime):
            subprocess.run(['sips', '-Z', str(px), '-s', 'format', 'jpeg', '-s', 'formatOptions', '88',
                            str(src), '--out', str(o)], check=True, capture_output=True)


def img(name, px=None):
    d = f'grid{px}/' if px else ''
    return f'file://{REPO}/input/img-hi/images-alphabet/{d}{name}.jpg'


def build(slug, mode):
    """mode: board | interior | cover. Returns (html path, pdf path)."""
    c = CFG[slug]; b = spec[c['book']]; ar = c['ar']
    lulu = mode in ('interior', 'cover')
    trim = 8.5 * IN if lulu else 180.0
    bleed = 0.125 * IN if lulu else 3.0
    safe = 0.5 * IN if lulu else 8.0
    sheet = trim + 2 * bleed
    pad = bleed + safe
    pages = b['pages']
    n = len(pages)
    direction = 'rtl' if ar else 'ltr'
    lang = b['lang']
    url = book_url(slug)
    marks = mode == 'board'
    interior_pages = 32
    spine = (interior_pages / 444 + 0.06) * IN

    def letter_of(p):
        return E(p['letter']) if ar else f"{E(p['letter'])} {E(p['lower'])}"

    # ---------- pages ----------
    secs = []

    def sheet_html(cls, inner, bg='#FCFBF6', label=''):
        m = ''
        if marks:
            m = ''.join(f'<i class="mark {k}"></i>' for k in ('tl', 'tr', 'bl', 'br'))
            m += f'<span class="folio">{E(label)}</span>' if label else ''
        return f'<section class="sheet {cls}" style="background:{bg}">{m}<div class="in">{inner}</div></section>'

    # title
    cover_img = b['cover']['img']
    title_inner = (f'<h1>{E(b["title"])}</h1><img class="hero" src="{img(cover_img)}" alt="">'
                   f'<p class="sub">{E(b["cover"]["line"])}</p>')
    # grid(s)
    def tile(i, p):
        t = TINTS[i % len(TINTS)]
        return (f'<div class="tile" style="background:{t}"><b>{letter_of(p)}</b>'
                f'<img src="{img(p["words"][0]["img"], 400 if ar else 600)}" alt=""></div>')
    tiles = [tile(i, p) for i, p in enumerate(pages)]
    if ar:
        grids = [f'<div class="grid g7">{"".join(tiles)}</div>']
        grid_pages = [sheet_html('grid', grids[0])]
    else:
        halves = [tiles[:13], tiles[13:]]
        grid_pages = [sheet_html('grid', f'<div class="grid g4">{"".join(h)}</div>') for h in halves]

    # letters
    letter_pages = []
    for i, p in enumerate(pages):
        t = TINTS[i % len(TINTS)]
        words = ''.join(
            f'<figure><img src="{img(w["img"])}" alt=""><figcaption>{E(w["word"])}</figcaption></figure>'
            for w in p['words'])
        note = ''
        if ar and p['letter'] in b.get('notes', {}):
            note = f'<p class="note">{E(b["notes"][p["letter"]])}</p>'
        inner = (f'<div class="big">{letter_of(p)}</div><div class="pair">{words}</div>'
                 f'<p class="line">{E(p["line"])}</p>{note}')
        letter_pages.append(sheet_html('letter', inner, bg=t, label=f'{i + 1}'))

    end = b['end']
    end_page = sheet_html('end', f'<img class="hero" src="{img(end["img"])}" alt="">'
                          f'<h2>{E(end["title"])}</h2><p class="sub">{E(end["line"])}</p>')
    qr = qr_svg(slug)
    # A Lulu interior carries no QR (the code is on the back cover); the board edition does.
    qrblock = (f'<div class="qr">{qr}</div><p class="sub">{E(c["listen"])}</p>'
               f'<p class="url">{E(url)}</p>') if not lulu else ''
    credit = f'<p class="small" dir="ltr">{E(CREDIT)}</p>'
    if ar:
        tail = [sheet_html('listen', f'<p class="sub">{E(c["made"])}</p>{qrblock}{credit}')]
    else:
        owner = sheet_html('owner', '<p class="sub">This book belongs to</p><div class="line-write"></div>')
        tail = [sheet_html('credits', f'<p class="sub">{E(c["made"])}</p>{qrblock}{credit}')]
    title_page = sheet_html('title', title_inner)
    front = [title_page] if ar else [title_page, owner]
    interior = front + grid_pages + letter_pages + [end_page] + tail
    assert len(interior) == interior_pages, (slug, len(interior))

    # ---------- cover spread ----------
    spread_w = trim * 2 + spine + 2 * bleed
    chips = ''.join(f'<span style="background:{TINTS[i % len(TINTS)]}">{E(p["letter"])}</span>'
                    for i, p in enumerate(pages))
    cover_html = f'''<section class="spread" style="width:{spread_w}mm;height:{sheet}mm">
      <div class="half back"><div class="bk"><p class="sub">{E(b["cover"]["line"])}</p>
        <div class="chips">{chips}</div>
        <div class="qr small-qr">{qr}</div><p class="url">{E(url)}</p></div></div>
      <div class="spine"></div>
      <div class="half front"><div class="fr"><h1>{E(b["title"])}</h1>
        <img class="hero" src="{img(cover_img)}" alt=""></div></div></section>'''

    if mode == 'cover':
        body = cover_html
        page_css = f'@page{{size:{spread_w}mm {sheet}mm;margin:0}}'
    else:
        body = ''.join(interior)
        page_css = f'@page{{size:{sheet}mm {sheet}mm;margin:0}}'

    font = '"Baloo Bhaijaan 2",system-ui,sans-serif' if ar else '"Fraunces",Georgia,serif'
    bodyfont = '"Baloo Bhaijaan 2",system-ui,sans-serif' if ar else '"Fredoka","Avenir Next Rounded",sans-serif'
    inner_w = trim - 2 * safe
    pic = (inner_w - 8) / 2          # two pictures side by side
    css = f'''
{page_css}
*{{box-sizing:border-box}}
html,body{{margin:0;padding:0;background:#FCFBF6;color:#1E1B16;font-family:{bodyfont}}}
:root{{--accent:#C2553A;--display:{font}}}
.sheet{{position:relative;width:{sheet}mm;height:{sheet}mm;padding:{pad}mm;overflow:hidden;
  page-break-after:always;break-after:page}}
.sheet:last-child{{page-break-after:auto;break-after:auto}}
.in{{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:5mm;text-align:center}}
h1,h2,.big{{font-family:var(--display);color:var(--accent);margin:0;font-weight:800;line-height:1.1}}
h1{{font-size:{44 if not ar else 56}pt}}
h2{{font-size:{30 if not ar else 36}pt}}
.hero{{width:112mm;height:112mm;object-fit:cover;border-radius:8mm}}
.sub{{font-size:{16 if not ar else 18}pt;margin:0;color:#5a554a;max-width:{inner_w}mm}}
.small{{font-size:9pt;color:#7D786B;margin:0;max-width:{inner_w}mm}}
.url{{font-size:10pt;color:#7D786B;margin:0;direction:ltr}}
.qr{{width:{inner_w * 0.42}mm;height:{inner_w * 0.42}mm}} .qr svg{{width:100%;height:100%}}
.line-write{{width:{inner_w * 0.6}mm;border-bottom:.4mm solid #7D786B;height:12mm}}
.big{{font-size:{(80 if not ar else 110)}pt}}
.pair{{display:flex;gap:8mm;direction:{direction}}}
.pair figure{{margin:0;width:{pic}mm;display:flex;flex-direction:column;align-items:center;gap:2mm}}
.pair img{{width:{pic}mm;height:{pic}mm;object-fit:cover;border-radius:6mm}}
figcaption{{font:700 {20 if not ar else 24}pt var(--display)}}
.line{{font-size:{16 if not ar else 18}pt;margin:0;color:#3d392f}}
.note{{font-size:12pt;margin:0;color:#6a655a;max-width:{inner_w}mm}}
.grid{{display:grid;gap:4mm;width:100%;direction:{direction}}}
.g4{{grid-template-columns:repeat(5,1fr)}} .g7{{grid-template-columns:repeat(7,1fr);gap:3mm}}
.tile{{border-radius:5mm;padding:2mm;display:flex;flex-direction:column;align-items:center;gap:1mm;
  font-family:var(--display);min-width:0}}
.tile b{{font-size:{16 if not ar else 20}pt;line-height:1.1}}
.tile img{{width:100%;aspect-ratio:1;object-fit:cover;border-radius:3mm}}
/* crop marks and folio live in the bleed */
.mark{{position:absolute;width:{bleed}mm;height:{bleed}mm;border:0 solid rgba(17,16,16,.55)}}
.mark.tl{{top:0;left:0;border-right-width:.2mm;border-bottom-width:.2mm}}
.mark.tr{{top:0;right:0;border-left-width:.2mm;border-bottom-width:.2mm}}
.mark.bl{{bottom:0;left:0;border-right-width:.2mm;border-top-width:.2mm}}
.mark.br{{bottom:0;right:0;border-left-width:.2mm;border-top-width:.2mm}}
.folio{{position:absolute;bottom:0;left:50%;transform:translateX(-50%);font-size:5pt;color:rgba(17,16,16,.5)}}
/* cover spread */
.spread{{display:flex;background:#F3D9C4;overflow:hidden}}
.half{{flex:0 0 {trim + bleed}mm;display:flex;align-items:center;justify-content:center;
  padding:{bleed + safe}mm {safe}mm}}
.half.back{{padding-left:{bleed + safe}mm}} .half.front{{padding-right:{bleed + safe}mm}}
.spine{{flex:0 0 {spine}mm;background:#F3D9C4}}
.fr,.bk{{display:flex;flex-direction:column;align-items:center;gap:6mm;text-align:center}}
.chips{{display:flex;flex-wrap:wrap;justify-content:center;gap:3mm;max-width:{trim - 2 * safe - 20}mm;direction:{direction}}}
.chips span{{width:14mm;height:14mm;border-radius:3.5mm;display:flex;align-items:center;justify-content:center;
  font:800 {18 if not ar else 22}pt var(--display);color:var(--accent);background:#fff}}
.spread .half.back{{background:#FCFBF6}}
.small-qr{{width:{trim * 0.2}mm;height:{trim * 0.2}mm}}
.bk{{margin-bottom:{32 + 6}mm}}   /* Lulu keeps 92 x 32mm free at the bottom of the back for a barcode */
'''
    doc = f'''<!DOCTYPE html><html lang="{lang}" dir="{direction}"><head><meta charset="utf-8">
<title>{E(b["title"])}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Bhaijaan+2:wght@400..800&family=Fraunces:opsz,wght@9..144,400..900&family=Fredoka:wght@400..700&display=swap">
<style>{css}</style></head><body>{body}</body></html>'''
    stem = {'board': f'{slug}-board', 'interior': f'{slug}-lulu-interior',
            'cover': f'{slug}-lulu-cover'}[mode] + c['sfx']
    (REPO / 'build').mkdir(exist_ok=True)
    (REPO / c['dest']).mkdir(parents=True, exist_ok=True)
    hp = REPO / 'build' / f'{stem}.html'
    pp = REPO / c['dest'] / f'{stem}.pdf'
    hp.write_text(doc)
    subprocess.run([CHROME, '--headless', '--no-pdf-header-footer', '--virtual-time-budget=20000',
                    f'--print-to-pdf={pp}', f'file://{hp}'], check=True, capture_output=True)
    print(f'  {pp.relative_to(REPO)}  {pp.stat().st_size / 1e6:.1f}MB')
    return hp, pp


if __name__ == '__main__':
    which = sys.argv[1:] or ['abc', 'huroof']
    for s in which:
        pictures({w['img'] for p in spec[CFG[s]['book']]['pages'] for w in p['words']}
                 | {spec[CFG[s]['book']]['cover']['img'], spec[CFG[s]['book']]['end']['img']})
        small({p['words'][0]['img'] for p in spec[CFG[s]['book']]['pages']}, 400 if CFG[s]['ar'] else 600)
        for m in ('board', 'interior', 'cover'):
            build(s, m)
