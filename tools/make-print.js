#!/usr/bin/env node
/**
 * Build a print-ready HTML edition of a story, for rendering to PDF.
 *
 *   node tools/make-print.js <book.html> <out.html> --url <listen-url> --qr <qr.svg>
 *
 * Reads the book's own page data rather than a second copy of the text: the
 * artwork and both languages are lifted straight out of the ART / BOOK objects,
 * so a printed edition can never drift from the screen one.
 *
 * One story page per sheet, artwork large, English and Arabic together, so a
 * single printed copy serves both. A QR on the cover opens the narrated version.
 */
'use strict';
const fs = require('fs');
const vm = require('vm');
const path = require('path');

function arg(flag, fallback) {
    const i = process.argv.indexOf(flag);
    return i > -1 ? process.argv[i + 1] : fallback;
}

const [, , bookPath, outPath] = process.argv;
if (!bookPath || !outPath) {
    console.error('usage: make-print.js <book.html> <out.html> --url <listen-url> --qr <qr.svg>');
    process.exit(1);
}
const listenUrl = arg('--url', '');
const qrPath = arg('--qr', '');

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

const qr = qrPath && fs.existsSync(qrPath) ? fs.readFileSync(qrPath, 'utf8') : '';
const esc = (s) => String(s == null ? '' : s);
// the screen version marks the child's name with a span; print it plainly
const plain = (s) => esc(s).replace(/<span class="babyname">([^<]*)<\/span>/g, '$1');

const sheets = [];
for (const key of Object.keys(BOOK)) {
    for (const page of BOOK[key].pages) {
        const accent = page.tint || BOOK[key].accent || '#D7263D';
        if (page.cover) {
            sheets.push(`
  <section class="sheet cover">
    <div class="art">${page.art}</div>
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
        <span class="url">${esc(listenUrl.replace(/^https?:\/\//, "").split("/")[0])}</span>
      </div>
    </div>` : ''}
  </section>`);
        } else {
            // the longest pages (the hadith page) overflow A5 at full size:
            // give them a smaller stage and tighter type rather than clipping
            const load = (page.en.line + page.en.sound + page.ar.line + page.ar.sound).length;
            const dense = load > 260 ? ' dense' : '';
            sheets.push(`
  <section class="sheet${dense}" style="--accent:${accent}">
    <div class="art">${page.art}</div>
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

fs.writeFileSync(outPath, `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${title}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Bhaijaan+2:wght@400..700&family=Fraunces:ital,opsz,wght@0,9..144,400..900;1,9..144,400..700&family=Fredoka:wght@400..600&family=Noto+Kufi+Arabic:wght@400..900&display=swap">
<style>
  @page { size: 148mm 210mm; margin: 0; }   /* A5 portrait — two to a sheet of A4 */
  :root{
    --ink:#111010; --paper:#FCFBF6; --quiet:#7E7A6E; --accent:#D7263D;
    --display:"Fraunces","Iowan Old Style",Georgia,serif;
    --body:"Fredoka","Avenir Next Rounded",system-ui,sans-serif;
    --ar:"Baloo Bhaijaan 2","Noto Kufi Arabic",system-ui,sans-serif;
  }
  *{box-sizing:border-box}
  html,body{margin:0;padding:0;background:var(--paper);color:var(--ink);font-family:var(--body)}

  .sheet{
    width:148mm; height:210mm; padding:12mm 12mm 10mm;
    display:flex; flex-direction:column; align-items:center; justify-content:flex-start;
    page-break-after:always; break-after:page; overflow:hidden; background:var(--paper);
  }
  /* text-heavy pages: the artwork yields, the words stay whole */
  .sheet.dense .art{width:74mm;height:74mm}
  .sheet.dense h2{font-size:20pt}
  .sheet.dense h2.ar{font-size:17pt}
  .sheet.dense .line{font-size:11pt;line-height:1.3}
  .sheet.dense .line.ar{font-size:11.5pt;line-height:1.5}
  .sheet.dense .sound{font-size:12.5pt}
  .sheet.dense .words{margin-top:4mm;gap:1.5mm}
  .sheet:last-child{page-break-after:auto;break-after:auto}

  .art{width:108mm;height:108mm;display:flex;align-items:center;justify-content:center;flex:none}
  .art svg{width:100%;height:100%;display:block}
  .art svg.breathe{animation:none!important}

  .words{margin-top:6mm;text-align:center;width:100%;display:flex;flex-direction:column;gap:2mm}
  h1{font-family:var(--display);font-weight:900;font-size:30pt;line-height:1;margin:0}
  h1 em{font-style:normal;color:var(--accent)}
  h2{font-family:var(--display);font-weight:900;font-size:26pt;line-height:1;margin:0;
     text-transform:uppercase;letter-spacing:.02em;color:var(--accent)}
  h2.ar{font-family:var(--ar);text-transform:none;letter-spacing:0;font-size:22pt;line-height:1.3}
  .line{font-size:13pt;line-height:1.35;margin:0}
  .line.ar{font-family:var(--ar);font-size:13pt;line-height:1.6}
  .sound{font-family:var(--display);font-style:italic;font-weight:600;font-size:15pt;margin:0;color:var(--accent)}
  .sound.ar{font-family:var(--ar);font-style:normal;font-weight:700}
  .eyebrow{font-family:var(--display);font-size:8pt;letter-spacing:.2em;text-transform:uppercase;color:var(--quiet);margin:0}
  hr{border:none;border-top:.4mm solid rgba(17,16,16,.14);width:38mm;margin:3mm auto 1mm}

  .cover .art{width:96mm;height:96mm}
  .cover h1{font-size:34pt}
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
</style>
</head>
<body>
${sheets.join('\n')}
</body>
</html>
`);

console.log(`${path.basename(outPath)} — ${sheets.length} sheets from ${path.basename(bookPath)}`);
