#!/usr/bin/env node
/**
 * Build a print-ready HTML edition of a story, for rendering to PDF.
 *
 *   node tools/make-print.js <book.html> <out.html> --url <listen-url> --qr <qr.svg>
 *   node tools/make-print.js <book.html> <out.html> --board ...   # board-book edition
 *
 * Reads the book's own page data rather than a second copy of the text: the
 * artwork and both languages are lifted straight out of the ART / BOOK objects,
 * so a printed edition can never drift from the screen one.
 *
 * One story page per sheet, artwork large, English and Arabic together, so a
 * single printed copy serves both. A QR on the cover opens the narrated version.
 *
 * Two formats:
 *   default   A5 portrait, no bleed — for printing at home on card and stapling.
 *   --board   180mm square trim with 3mm bleed, crop marks and a folio in the
 *             bleed, for printing single-sided on heavy card, laminating, and
 *             gluing back-to-back into a board book a baby can chew on. The
 *             square shape is what board books are: it sits open on its own and
 *             small hands can grip an edge without covering the picture.
 */
'use strict';
const fs = require('fs');
const vm = require('vm');
const path = require('path');

function arg(flag, fallback) {
    const i = process.argv.indexOf(flag);
    return i > -1 ? process.argv[i + 1] : fallback;
}
const has = (flag) => process.argv.indexOf(flag) > -1;

const [, , bookPath, outPath] = process.argv;
if (!bookPath || !outPath) {
    console.error('usage: make-print.js <book.html> <out.html> --url <listen-url> --qr <qr.svg> [--board]');
    process.exit(1);
}
const listenUrl = arg('--url', '');
const qrPath = arg('--qr', '');
const board = has('--board');
// which artwork: the hand-drawn SVG the book opens with, or the generated
// illustrations behind the book's own artwork toggle
const useImages = arg('--art', 'drawn') === 'images';
const trim = Number(arg('--trim', 180));   // finished page, mm square
const bleed = Number(arg('--bleed', 3));   // trimmed off; artwork runs into it
const safe = Number(arg('--safe', 8));     // keep words this far inside the trim
const sheet = trim + bleed * 2;

// ---- lift the data out of the book ------------------------------------------
// Everything from the colour constants to the UI strings is pure data: template
// literals and object literals, no DOM. Evaluating just that slice gives us the
// real artwork and text without duplicating either.
const html = fs.readFileSync(bookPath, 'utf8');
const from = html.indexOf('var INK =');
const to = html.indexOf('var UI = {');
if (from < 0 || to < 0) {
    console.error('could not find the data section in', bookPath);
    process.exit(1);
}
const sandbox = { console };
vm.createContext(sandbox);
vm.runInContext(html.slice(from, to), sandbox);
const BOOK = sandbox.BOOK;

// A book with more than one chapter gets a code per chapter cover, so the
// colour zoo opens the colour chapter rather than the front of the book. The
// per-chapter file sits beside the default one as <name>-<chapter>.svg.
function qrFor(chapter) {
    if (!qrPath) return '';
    const perChapter = qrPath.replace(/\.svg$/, `-${chapter}.svg`);
    const file = fs.existsSync(perChapter) ? perChapter : qrPath;
    return fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
}

// The book stores generated artwork as a path relative to itself; the print
// file usually lives a directory down, so re-base it. Missing files fall back
// to the drawing rather than printing a hole.
const rebase = path.relative(path.dirname(path.resolve(outPath)), path.dirname(path.resolve(bookPath)));
const bookDir = path.dirname(bookPath);
function artworkOf(page) {
    if (useImages && page.img) {
        // prefer a JPEG made for print: the same picture at a twentieth of the
        // bytes, which is the difference between a mailable PDF and a 14MB one
        const jpg = path.join('print', 'img', page.img.replace(/\.png$/, '.jpg'));
        for (const rel of [fs.existsSync(path.join(bookDir, jpg)) ? jpg : null, page.img]) {
            if (rel && fs.existsSync(path.join(bookDir, rel))) {
                return `<img src="${path.join(rebase, rel)}" alt="">`;
            }
        }
    }
    return page.art;
}
const esc = (s) => String(s == null ? '' : s);
// the screen version marks the child's name with a span; print it plainly
const plain = (s) => esc(s).replace(/<span class="babyname">([^<]*)<\/span>/g, '$1');

// Crop marks and the folio live inside the bleed, so the trim knife removes
// them. They are the only way to cut a stack of card squarely by hand, and the
// folio is the only way to keep forty loose sheets in order while gluing.
const marks = (n) => !board ? '' : `
    <i class="mark tl"></i><i class="mark tr"></i><i class="mark bl"></i><i class="mark br"></i>
    <i class="folio">${n}</i>`;

const sheets = [];
let n = 0;
for (const key of Object.keys(BOOK)) {
    for (const page of BOOK[key].pages) {
        const accent = page.tint || BOOK[key].accent || '#D7263D';
        n += 1;
        if (page.cover) {
            const qr = qrFor(key);
            sheets.push(`
  <section class="sheet cover">${marks(n)}
    <div class="art">${artworkOf(page)}</div>
    <div class="words">
      <p class="eyebrow">${plain(page.en.eyebrow)}</p>
      <h1>${plain(page.en.title).replace(/<em>/g, '<em>')}</h1>
      <p class="line">${plain(page.en.line)}</p>
      <p class="line ar" dir="rtl" lang="ar">${plain(page.ar.line)}</p>
    </div>
    ${qr ? `<div class="listen">
      <div class="qr">${qr}</div>
      <div class="listen-text">
        <b>Scan to listen</b>
        <span>Every page read aloud, in English and Arabic.</span>
        <span class="url">${esc(listenUrl.replace(/^https?:\/\//, "").split("/").slice(0, 2).join("/"))}</span>
      </div>
    </div>` : ''}
  </section>`);
        } else {
            // the longest pages (the hadith page) overflow at full size:
            // give them a smaller stage and tighter type rather than clipping
            const load = (page.en.line + page.en.sound + page.ar.line + page.ar.sound).length;
            // the square board page has less height to spare than A5, so it
            // needs a middle setting between a full stage and a cramped one
            const dense = load > 260 ? ' dense' : (board && load > 190 ? ' snug' : '');
            sheets.push(`
  <section class="sheet${dense}" style="--accent:${accent}">${marks(n)}
    <div class="art">${artworkOf(page)}</div>
    <div class="words">
      <h2>${plain(page.en.name)}</h2>
      <p class="line">${plain(page.en.line)}</p>
      <p class="sound">${plain(page.en.sound)}</p>
      <hr>
      <h2 class="ar" dir="rtl" lang="ar">${plain(page.ar.name)}</h2>
      <p class="line ar" dir="rtl" lang="ar">${plain(page.ar.line)}</p>
      <p class="sound ar" dir="rtl" lang="ar">${plain(page.ar.sound)}</p>
    </div>
  </section>`);
        }
    }
}

const title = (html.match(/<title>([^<]*)<\/title>/) || [, 'Story'])[1];

// ---- geometry ---------------------------------------------------------------
const page = board
    ? `@page { size: ${sheet}mm ${sheet}mm; margin: 0; }   /* ${trim}mm square trim + ${bleed}mm bleed */`
    : `@page { size: 148mm 210mm; margin: 0; }   /* A5 portrait — two to a sheet of A4 */`;

const geometry = board ? `
  .sheet{
    width:${sheet}mm; height:${sheet}mm; padding:${bleed + safe}mm;
    position:relative;
  }
  /* a baby is looking at the picture, not the words: give it the page */
  .sheet:not(.cover){justify-content:center}
  .art{width:112mm;height:112mm}
  .sheet.snug .art{width:92mm;height:92mm}
  .sheet.dense .art{width:76mm;height:76mm}
  .words{margin-top:5mm}
  h1{font-size:34pt}
  h2{font-size:27pt}
  h2.ar{font-size:23pt}
  .line{font-size:14pt;line-height:1.35}
  .line.ar{font-size:14pt;line-height:1.6}
  .sound{font-size:16pt}
  .sheet.dense h2{font-size:21pt}
  .sheet.dense h2.ar{font-size:18pt}
  .sheet.dense .line{font-size:11.5pt;line-height:1.3}
  .sheet.dense .line.ar{font-size:12pt;line-height:1.5}
  .sheet.dense .sound{font-size:13pt}
  .sheet.dense .words{margin-top:4mm;gap:1.5mm}
  /* the cover also carries the title block and the 34mm QR panel: at a full
     stage the panel ran off the bottom of the square page and the QR was
     clipped to the point where it would not scan */
  .cover .art{width:74mm;height:74mm}
  .cover h1{font-size:34pt}

  /* crop marks and folio sit in the bleed — the trim removes them */
  .qr{width:34mm;height:34mm}
  .listen-text b{font-size:12pt}
  .mark{position:absolute;width:${bleed}mm;height:${bleed}mm;border:0 solid rgba(17,16,16,.55)}
  .mark.tl{top:0;left:0;border-top-width:.25mm;border-left-width:.25mm}
  .mark.tr{top:0;right:0;border-top-width:.25mm;border-right-width:.25mm}
  .mark.bl{bottom:0;left:0;border-bottom-width:.25mm;border-left-width:.25mm}
  .mark.br{bottom:0;right:0;border-bottom-width:.25mm;border-right-width:.25mm}
  .folio{
    position:absolute;bottom:.4mm;left:50%;transform:translateX(-50%);
    font-family:var(--body);font-style:normal;font-size:5pt;color:rgba(17,16,16,.5);
  }
` : `
  .sheet{
    width:148mm; height:210mm; padding:12mm 12mm 10mm;
  }
  .art{width:108mm;height:108mm}
  /* text-heavy pages: the artwork yields, the words stay whole */
  .sheet.dense .art{width:74mm;height:74mm}
  .sheet.dense h2{font-size:20pt}
  .sheet.dense h2.ar{font-size:17pt}
  .sheet.dense .line{font-size:11pt;line-height:1.3}
  .sheet.dense .line.ar{font-size:11.5pt;line-height:1.5}
  .sheet.dense .sound{font-size:12.5pt}
  .sheet.dense .words{margin-top:4mm;gap:1.5mm}
  .words{margin-top:6mm}
  h1{font-size:30pt}
  h2{font-size:26pt}
  h2.ar{font-size:22pt}
  .line{font-size:13pt;line-height:1.35}
  .line.ar{font-size:13pt;line-height:1.6}
  .sound{font-size:15pt}
  .cover .art{width:96mm;height:96mm}
  .cover h1{font-size:34pt}
`;

fs.writeFileSync(outPath, `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${title}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Bhaijaan+2:wght@400..700&family=Fraunces:ital,opsz,wght@0,9..144,400..900;1,9..144,400..700&family=Fredoka:wght@400..600&family=Noto+Kufi+Arabic:wght@400..900&display=swap">
<style>
  ${page}
  :root{
    --ink:#111010; --paper:#FCFBF6; --quiet:#7E7A6E; --accent:#D7263D;
    --display:"Fraunces","Iowan Old Style",Georgia,serif;
    --body:"Fredoka","Avenir Next Rounded",system-ui,sans-serif;
    --ar:"Baloo Bhaijaan 2","Noto Kufi Arabic",system-ui,sans-serif;
  }
  *{box-sizing:border-box}
  html,body{margin:0;padding:0;background:var(--paper);color:var(--ink);font-family:var(--body)}

  .sheet{
    display:flex; flex-direction:column; align-items:center; justify-content:flex-start;
    page-break-after:always; break-after:page; overflow:hidden; background:var(--paper);
  }
  .sheet:last-child{page-break-after:auto;break-after:auto}

  .art{display:flex;align-items:center;justify-content:center;flex:none}
  .art svg,.art img{width:100%;height:100%;display:block;object-fit:contain}
  .art img{border-radius:3mm}
  .art svg.breathe{animation:none!important}

  .words{text-align:center;width:100%;display:flex;flex-direction:column;gap:2mm}
  h1{font-family:var(--display);font-weight:900;line-height:1;margin:0}
  h1 em{font-style:normal;color:var(--accent)}
  h2{font-family:var(--display);font-weight:900;line-height:1;margin:0;
     text-transform:uppercase;letter-spacing:.02em;color:var(--accent)}
  h2.ar{font-family:var(--ar);text-transform:none;letter-spacing:0;line-height:1.3}
  .line{margin:0}
  .line.ar{font-family:var(--ar)}
  .sound{font-family:var(--display);font-style:italic;font-weight:600;margin:0;color:var(--accent)}
  .sound.ar{font-family:var(--ar);font-style:normal;font-weight:700}
  .eyebrow{font-family:var(--display);font-size:8pt;letter-spacing:.2em;text-transform:uppercase;color:var(--quiet);margin:0}
  hr{border:none;border-top:.4mm solid rgba(17,16,16,.14);width:38mm;margin:3mm auto 1mm}

  .listen{
    margin-top:auto;display:flex;align-items:center;gap:5mm;width:100%;
    border-top:.4mm solid rgba(17,16,16,.16);padding-top:5mm;
  }
  .qr{width:30mm;height:30mm;flex:none}
  .qr svg{width:100%;height:100%;display:block}
  .listen-text{display:flex;flex-direction:column;gap:1mm;text-align:left}
  .listen-text b{font-size:11pt}
  .listen-text span{font-size:8.5pt;color:#4A463D;line-height:1.35}
  .listen-text .url{font-size:7.5pt;color:var(--quiet);letter-spacing:.04em}
${geometry}
</style>
</head>
<body>
${sheets.join('\n')}
</body>
</html>
`);

console.log(`${path.basename(outPath)} — ${sheets.length} sheets from ${path.basename(bookPath)}`
    + (board ? `, ${trim}mm square + ${bleed}mm bleed` : ', A5'));
