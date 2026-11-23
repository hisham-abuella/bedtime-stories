#!/usr/bin/env python3
"""Build the two alphabet books from stories/alphabet.json.

  python3 tools/build-alphabet.py

  books/abc.html      My ABC, English
  books/huroof.html   حروفي, Egyptian Arabic

Each opens on a grid of every letter. Tapping a letter opens it with its
pictures and words, and the voice-over (audio-<slug>/<n>.mp3) reads it. The lullaby under the
voice comes from books/lullaby.js, shared by every book. Pictures are images-alphabet/<thing>.png, shared
by both books.
"""
import json, html
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
spec = json.loads((REPO / 'stories/alphabet.json').read_text())
TINTS = ['#F3D9C4', '#DDE8D2', '#D6E3EC', '#F1E2B8', '#E9D5E3', '#D9E6E1', '#F0D4CC']

UI = {
    'en': {'all': 'All letters', 'prev': 'Back', 'next': 'Next', 'play': 'Say it again',
           'music': 'Lullaby', 'shelf': 'Bookshelf', 'start': 'Start at A',
           'credit': 'Lullaby: “Lullaby (Johannes Brahms)” by BrunoXe, CC BY 3.0.'},
    'eg': {'all': 'كل الحروف', 'prev': 'اللي فات', 'next': 'اللي بعده', 'play': 'قولها تاني',
           'music': 'تهويدة', 'shelf': 'المكتبة', 'start': 'يلا نبدأ',
           'credit': 'Lullaby: “Lullaby (Johannes Brahms)” by BrunoXe, CC BY 3.0.'},
}

def build(book):
    b = spec[book]; ui = UI[book]; slug = b['slug']
    pages = [dict(p, tint=TINTS[i % len(TINTS)]) for i, p in enumerate(b['pages'])]
    data = {'slug': slug, 'cover': b['cover'], 'end': b['end'], 'pages': pages, 'ui': ui}
    title = html.escape(b['title'])
    rtl = b['dir'] == 'rtl'
    return f'''<!DOCTYPE html>
<html lang="{b['lang']}" dir="{b['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{html.escape(b['cover']['line'])}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{html.escape(b['cover']['line'])}">
<link rel="icon" href="data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20100%20100'%3E%3Ctext%20y='.9em'%20font-size='90'%3E%F0%9F%94%A4%3C/text%3E%3C/svg%3E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Bhaijaan+2:wght@400..800&family=Fraunces:opsz,wght@9..144,400..900&family=Fredoka:wght@400..700&display=swap">
<style>
  :root{{
    --page:#FCFBF6; --ink:#1E1B16; --quiet:#7D786B; --accent:#C2553A;
    --surround:#1C1B17; --surround-2:#262519;
    --display:{'"Baloo Bhaijaan 2",system-ui,sans-serif' if rtl else '"Fraunces",Georgia,serif'};
    --story:{'"Baloo Bhaijaan 2",system-ui,sans-serif' if rtl else '"Fredoka","Avenir Next Rounded",system-ui,sans-serif'};
  }}
  *{{box-sizing:border-box}}
  body{{margin:0;min-height:100vh;color:var(--page);font-family:var(--story);
    background:radial-gradient(120% 80% at 50% 0%,var(--surround-2) 0%,var(--surround) 62%);
    padding:16px 16px 32px;display:flex;flex-direction:column;align-items:center;gap:14px}}
  .bar{{width:min(860px,100%);display:flex;gap:8px;justify-content:space-between;align-items:center;flex-wrap:wrap}}
  .bar a,.bar button{{font:600 .9rem var(--story);color:#E9E4D3;background:rgba(252,251,246,.08);
    border:1px solid rgba(252,251,246,.16);border-radius:999px;padding:8px 14px;cursor:pointer;text-decoration:none}}
  .bar button[aria-pressed="true"]{{background:var(--accent);border-color:var(--accent);color:#fff}}
  .bar .group{{display:flex;gap:8px}}
  .sheet{{width:min(860px,100%);background:var(--page);color:var(--ink);border-radius:22px;
    padding:clamp(16px,4vw,36px);box-shadow:0 20px 60px rgba(0,0,0,.35)}}
  /* grid */
  .cover{{display:flex;flex-direction:column;align-items:center;text-align:center;gap:6px;margin-bottom:18px}}
  .cover img{{width:min(220px,50vw);aspect-ratio:1;border-radius:18px;object-fit:cover}}
  .cover h1{{font:800 clamp(2.2rem,8vw,3.6rem)/1 var(--display);margin:6px 0 0;color:var(--accent)}}
  .cover p{{margin:0;color:var(--quiet);font-size:1.05rem}}
  .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(84px,1fr));gap:10px}}
  .tile{{border:none;border-radius:16px;padding:8px 6px 6px;cursor:pointer;display:flex;flex-direction:column;
    align-items:center;gap:2px;font-family:var(--display);color:var(--ink);transition:transform .15s}}
  .tile:hover,.tile:focus-visible{{transform:translateY(-3px)}}
  .tile b{{font-size:2.1rem;line-height:1.1}}
  .tile img{{width:100%;aspect-ratio:1;object-fit:cover;border-radius:10px}}
  /* letter */
  .letter{{display:grid;grid-template-columns:minmax(0,1fr);gap:14px;text-align:center}}  /* else the 1024px pictures widen the column */
  .big{{font:800 clamp(4.5rem,20vw,8rem)/1.35 var(--display);color:var(--accent);margin:0;padding-top:.1em}}
  .big small{{font-size:.55em;color:var(--ink);opacity:.55;margin-inline-start:.15em}}
  .things{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:clamp(8px,2vw,14px)}}  /* both pictures in view, even on a phone */
  .thing{{margin:0;border-radius:18px;padding:clamp(6px,1.5vw,10px);cursor:pointer;min-width:0}}
  .thing img{{width:100%;aspect-ratio:1;object-fit:cover;border-radius:12px;display:block}}
  .thing figcaption{{font:700 clamp(1.5rem,5vw,2.1rem)/1.2 var(--story);margin-top:8px}}
  .thing figcaption .first{{color:var(--accent)}}  /* English only: splitting an Arabic word into spans can break its letter joins */
  .line{{font-size:1.15rem;margin:0}}
  .note{{font-size:.95rem;color:var(--quiet);margin:0}}
  .nav{{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap}}
  .nav button{{font:700 1rem var(--story);border:none;border-radius:999px;padding:12px clamp(12px,3vw,20px);cursor:pointer;
    background:#EFE9DA;color:var(--ink)}}
  .nav button.say{{background:var(--accent);color:#fff}}
  .end{{text-align:center}}
  .end img{{width:min(240px,55vw);border-radius:18px}}
  .credit{{font-size:.75rem;color:#9C978A;text-align:center;max-width:860px}}
  .credit a{{color:inherit}}
  [hidden]{{display:none!important}}
</style>
</head>
<body>
<div class="bar">
  <a href="../index.html">← {ui['shelf']}</a>
  <div class="group">
    <button id="home" type="button">{ui['all']}</button>
  </div>
</div>
<main class="sheet" id="sheet" aria-live="polite"></main>
<audio id="voice" preload="none"></audio>
<script>
const BOOK = {json.dumps(data, ensure_ascii=False)};
const sheet = document.getElementById('sheet'), voice = document.getElementById('voice');
const img = k => '../images-alphabet/' + k + '.png';
const esc = s => s.replace(/[&<>"]/g, c => ({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}}[c]));
let current = -1;   // -1 grid, 0..n-1 letters, n the end page

function say(n) {{   // n: 0 cover, 1..n letters, n+1 end
  voice.src = '../audio-' + BOOK.slug + '/p' + n + '.mp3';
  voice.play().catch(() => {{}});
}}
voice.addEventListener('error', () => {{}});

function grid() {{
  current = -1; history.replaceState(null, '', '#');
  sheet.innerHTML = `<div class="cover"><img src="${{img(BOOK.cover.img)}}" alt="">
    <h1>${{esc(BOOK.cover.title)}}</h1><p>${{esc(BOOK.cover.line)}}</p></div>
    <div class="grid">${{BOOK.pages.map((p, i) => `<button class="tile" style="background:${{p.tint}}" data-i="${{i}}"
      aria-label="${{esc(p.letter)}}"><b>${{esc(p.letter)}}</b><img src="${{img(p.words[0].img)}}" alt="" loading="lazy"></button>`).join('')}}</div>
    <div class="nav" style="margin-top:16px;justify-content:center"><button class="say" data-i="0">${{BOOK.ui.start}}</button></div>`;
  sheet.querySelectorAll('[data-i]').forEach(b => b.onclick = () => open(+b.dataset.i));
}}

function open(i) {{
  const n = BOOK.pages.length;
  if (i < 0) return grid();
  current = Math.min(i, n); history.replaceState(null, '', '#' + (current + 1));
  if (current === n) {{
    sheet.innerHTML = `<div class="end"><img src="${{img(BOOK.end.img)}}" alt=""><h1 class="big" style="font-size:clamp(2rem,7vw,3.2rem)">${{esc(BOOK.end.title)}}</h1>
      <p class="line">${{esc(BOOK.end.line)}}</p></div><div class="nav" style="margin-top:16px">
      <button data-go="${{n - 1}}">${{BOOK.ui.prev}}</button><button class="say" data-go="-1">${{BOOK.ui.all}}</button></div>`;
    say(n + 1);
  }} else {{
    const p = BOOK.pages[i];
    const word = w => `<span class="first">${{esc(w.slice(0, 1))}}</span>${{esc(w.slice(1))}}`;
    sheet.innerHTML = `<div class="letter">
      <p class="big">${{esc(p.letter)}}${{p.lower ? `<small>${{esc(p.lower)}}</small>` : ''}}</p>
      <div class="things">${{p.words.map(w => `<figure class="thing" style="background:${{p.tint}}">
        <img src="${{img(w.img)}}" alt="${{esc(w.word)}}"><figcaption>${{BOOK.slug === 'abc' && p.letter !== 'X' ? word(w.word) : esc(w.word)}}</figcaption></figure>`).join('')}}</div>
      ${{p.note ? `<p class="note">${{esc(p.note)}}</p>` : ''}}
      <div class="nav"><button data-go="${{i - 1}}">${{BOOK.ui.prev}}</button>
        <button class="say" data-say="1">▶ ${{BOOK.ui.play}}</button>
        <button data-go="${{i + 1}}">${{BOOK.ui.next}}</button></div></div>`;
    say(i + 1);
  }}
  sheet.querySelectorAll('[data-go]').forEach(b => b.onclick = () => open(+b.dataset.go));
  sheet.querySelectorAll('[data-say],.thing').forEach(b => b.onclick = () => say(current + 1));
  window.scrollTo(0, 0);
}}

document.getElementById('home').onclick = grid;
// Arrow keys and swipes follow the reading direction.
const rtl = document.dir === 'rtl';
document.addEventListener('keydown', e => {{
  if (current < 0) return;
  if (e.key === (rtl ? 'ArrowLeft' : 'ArrowRight')) open(current + 1);
  if (e.key === (rtl ? 'ArrowRight' : 'ArrowLeft')) open(current - 1);
}});
let x0 = null;
sheet.addEventListener('touchstart', e => x0 = e.touches[0].clientX, {{passive: true}});
sheet.addEventListener('touchend', e => {{
  if (x0 === null || current < 0) return;
  const dx = e.changedTouches[0].clientX - x0; x0 = null;
  if (Math.abs(dx) < 50) return;
  open(current + ((dx < 0) !== rtl ? 1 : -1));
}});


const start = parseInt(location.hash.slice(1), 10);
start > 0 ? open(start - 1) : grid();
</script>
<script src="lullaby.js" defer></script>
</body>
</html>
'''

for book in ('en', 'eg'):
    out = REPO / 'books' / (spec[book]['slug'] + '.html')
    out.write_text(build(book))
    print(out.relative_to(REPO))
