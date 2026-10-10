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
 * Three formats:
 *   default   A5 portrait, no bleed — for printing at home on card and stapling.
 *   --board   180mm square trim with 3mm bleed, crop marks and a folio in the
 *             bleed, for printing single-sided on heavy card, laminating, and
 *             gluing back-to-back into a board book a baby can chew on. The
 *             square shape is what board books are: it sits open on its own and
 *             small hands can grip an edge without covering the picture.
 *   --lulu    Lulu's Small Square (7.5in trim, 0.125in bleed, 0.5in safety),
 *             saddle stitched. Their preflight rejects what the board edition
 *             depends on, so this format differs in four ways: no crop marks or
 *             folio ("do NOT include trim, bleed, or margin lines"), a 0.5in
 *             safety margin instead of 8mm, the front cover lifted out into its
 *             own spread (--cover), and the interior padded with blanks to a
 *             multiple of four, because a saddle-stitched sheet folds into four
 *             pages and Lulu would otherwise choose where the blanks land.
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
// Lulu's Small Square, saddle stitched. Their numbers, in inches, because the
// trim is specified in inches and rounding it through mm moves the cut line.
const lulu = has('--lulu');
// Which Arabic sits under the English: the fusha the books are written in, or
// the Egyptian of the مصري switch. Same page, same picture, different column.
const dialect = arg('--dialect', 'ar') === 'eg' ? 'eg' : 'ar';
const arOf = (p) => (dialect === 'eg' && p.eg) ? p.eg : p.ar;
const arLang = dialect === 'eg' ? 'ar-EG' : 'ar';
const coverSpread = has('--cover');
// which artwork: the hand-drawn SVG the book opens with, or the generated
// illustrations behind the book's own artwork toggle
const useImages = arg('--art', 'drawn') === 'images';
const IN = 25.4;
const trim = Number(arg('--trim', lulu ? 7.5 * IN : 180));        // finished page, mm square
const bleed = Number(arg('--bleed', lulu ? 0.125 * IN : 3));      // trimmed off; artwork runs into it
const safe = Number(arg('--safe', lulu ? 0.5 * IN : 8));          // keep words this far inside the trim
const sheet = trim + bleed * 2;
// both square formats share a geometry; only the numbers and the marks differ
const square = board || lulu;

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
        // Lulu wants 300ppi minimum. The shipped art is 1024px, which is 241ppi
        // inside a 108mm box, so the print build looks first for the 1536px
        // re-render in print/img-hi. Falling through to the 1024px copy would
        // pass preflight on the small stages and fail on the large ones, so
        // build-lulu.sh refuses to run until the hi-res set is complete.
        const hi = path.join('print', 'img-hi', page.img.replace(/\.png$/, '.jpg'));
        const order = lulu
            ? [hi, jpg, page.img]
            : [fs.existsSync(path.join(bookDir, jpg)) ? jpg : null, page.img];
        for (const rel of order) {
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
// The front cover is the book's first cover page. A multi-chapter book has
// more than one — the colour zoo's second chapter opens with its own — and
// those stay in the interior, where they belong.
let front = null;
for (const key of Object.keys(BOOK)) {
    for (const page of BOOK[key].pages) {
        const accent = page.tint || BOOK[key].accent || '#D7263D';
        n += 1;
        if (page.cover) {
            const qr = qrFor(key);
            if (!front) front = { page, qr };
            // Lulu takes the cover as its own spread file, so it must not also
            // appear as interior page one.
            if (lulu && front.page === page) continue;
            sheets.push(`
  <section class="sheet cover">${marks(n)}
    <div class="art">${artworkOf(page)}</div>
    <div class="words">
      <p class="eyebrow">${plain(page.en.eyebrow)}</p>
      <h1>${plain(page.en.title).replace(/<em>/g, '<em>')}</h1>
      <p class="line">${plain(page.en.line)}</p>
      <p class="line ar" dir="rtl" lang="${arLang}">${plain(arOf(page).line)}</p>
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
            const load = (page.en.line + page.en.sound + arOf(page).line + arOf(page).sound).length;
            // the square board page has less height to spare than A5, so it
            // needs a middle setting between a full stage and a cramped one
            // thresholds are measured, not guessed: on the square page a full
            // stage starts pushing the last line off at about 150 characters,
            // and a snug stage at about 245
            const dense = load > 245 ? ' dense' : (load > 150 ? ' snug' : '');
            sheets.push(`
  <section class="sheet${dense}" style="--accent:${accent}">${marks(n)}
    <div class="art">${artworkOf(page)}</div>
    <div class="words">
      <h2>${plain(page.en.name)}</h2>
      <p class="line">${plain(page.en.line)}</p>
      <p class="sound">${plain(page.en.sound)}</p>
      <hr>
      <h2 class="ar" dir="rtl" lang="${arLang}">${plain(arOf(page).name)}</h2>
      <p class="line ar" dir="rtl" lang="${arLang}">${plain(arOf(page).line)}</p>
      <p class="sound ar" dir="rtl" lang="${arLang}">${plain(arOf(page).sound)}</p>
    </div>
  </section>`);
        }
    }
}

const title = (html.match(/<title>([^<]*)<\/title>/) || [, 'Story'])[1];

// ---- the cover spread -------------------------------------------------------
// Lulu wants one page holding back cover, spine and front cover. Saddle stitch
// has no spine — the sheets fold rather than stack against a flat edge — so the
// spread is simply two trims side by side. The QR moves to the back, which is
// where a reader looks for it anyway.
if (coverSpread) {
    if (!front) {
        console.error('no cover page found in', bookPath);
        process.exit(1);
    }
    const { page: c, qr } = front;
    sheets.length = 0;
    sheets.push(`
  <section class="spread">
    <div class="half back">
      <div class="back-top">
        <p class="eyebrow">${plain(c.en.eyebrow)}</p>
        <h2 class="back-title">${plain(c.en.title).replace(/<br\s*\/?>/gi, ' ').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim()}</h2>
        <p class="line">${plain(c.en.line)}</p>
        <p class="line ar" dir="rtl" lang="${arLang}">${plain(arOf(c).line)}</p>
      </div>
      ${qr ? `<div class="listen">
        <div class="qr">${qr}</div>
        <div class="listen-text">
          <b>Scan to listen</b>
          <span>Every page read aloud, in English and Arabic.</span>
          <span class="url">${esc(listenUrl.replace(/^https?:\/\//, "").split("/").slice(0, 2).join("/"))}</span>
        </div>
      </div>` : ''}
    </div>
    <div class="half front">
      <div class="art">${artworkOf(c)}</div>
      <div class="words">
        <p class="eyebrow">${plain(c.en.eyebrow)}</p>
        <h1>${plain(c.en.title)}</h1>
        <p class="line">${plain(c.en.line)}</p>
        <p class="line ar" dir="rtl" lang="${arLang}">${plain(arOf(c).line)}</p>
      </div>
    </div>
  </section>`);
}

// ---- blanks to a multiple of four -------------------------------------------
// A saddle-stitched sheet folds into four pages, so the interior count has to
// be a multiple of four. Lulu will add the blanks itself if we don't, but then
// they land wherever its imposition puts them; added here they land at the end.
let padded = 0;
if (lulu && !coverSpread) {
    while (sheets.length % 4) { sheets.push('\n  <section class="sheet blank"></section>'); padded += 1; }
}

// ---- geometry ---------------------------------------------------------------
const spreadW = trim * 2 + bleed * 2;   // two trims side by side, one bleed each outer edge
const page = coverSpread
    ? `@page { size: ${spreadW}mm ${sheet}mm; margin: 0; }   /* back + front spread, no spine: saddle stitch has none */`
    : square
        ? `@page { size: ${sheet}mm ${sheet}mm; margin: 0; }   /* ${trim}mm square trim + ${bleed}mm bleed */`
        : `@page { size: 148mm 210mm; margin: 0; }   /* A5 portrait — two to a sheet of A4 */`;

const geometry = square ? `
  .sheet{
    width:${sheet}mm; height:${sheet}mm; padding:${bleed + safe}mm;
    position:relative;
  }
  /* a baby is looking at the picture, not the words: give it the page */
  .sheet:not(.cover){justify-content:center}
  .art{width:108mm;height:108mm}
  .sheet.snug .art{width:82mm;height:82mm}
  .sheet.dense .art{width:72mm;height:72mm}
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
  .cover .art{width:66mm;height:66mm}
  .cover h1{font-size:34pt}

  /* Lulu's 0.5in safety margin takes 9.4mm more off each side than the board
     edition's 8mm, so every stage comes down to match. Measured, not guessed. */
  ${lulu ? `
  .art{width:92mm;height:92mm}
  .sheet.snug .art{width:74mm;height:74mm}
  .sheet.dense .art{width:64mm;height:64mm}
  .cover .art{width:62mm;height:62mm}
  .words{margin-top:4mm}
  .sheet.blank{background:var(--paper)}
  ` : ''}

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
  .sheet.snug .art{width:88mm;height:88mm}
  .sheet.dense .art{width:74mm;height:74mm}
  .sheet.snug h2{font-size:23pt}
  .sheet.snug h2.ar{font-size:19pt}
  .sheet.snug .line{font-size:12pt;line-height:1.32}
  .sheet.snug .line.ar{font-size:12.5pt;line-height:1.55}
  .sheet.snug .sound{font-size:14pt}
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
${coverSpread ? `
  /* The spread is two trims wide. Content keeps the full safety margin from
     every trimmed edge and from the fold, because Lulu's trimming tolerance is
     0.125in toward either cover and a saddle-stitch fold wanders a little. */
  .spread{
    width:${spreadW}mm; height:${sheet}mm; display:flex; overflow:hidden;
    background:var(--paper);
  }
  .half{
    flex:1 1 0; min-width:0; display:flex; flex-direction:column;
    align-items:center; padding:${bleed + safe}mm ${safe}mm;
  }
  .half.back{padding-left:${bleed + safe}mm; justify-content:flex-start}
  .half.front{padding-right:${bleed + safe}mm; justify-content:flex-start}
  .front .art{width:96mm;height:96mm}
  .front .words{margin-top:5mm}
  .front h1{font-size:34pt}
  .back{text-align:center}
  .back-top{display:flex;flex-direction:column;gap:3mm;width:100%}
  .back-title{
    font-family:var(--display);font-weight:900;font-size:19pt;line-height:1.05;
    margin:0;text-transform:none;letter-spacing:0;color:var(--ink);
  }
  .back .line{font-size:13pt;line-height:1.4}
  .back .line.ar{font-size:13pt;line-height:1.6}
  .back .listen{margin-top:auto}
` : ''}
</style>
</head>
<body>
${sheets.join('\n')}
</body>
</html>
`);

const fmt = (mm) => `${(mm / IN).toFixed(3).replace(/0+$/, '').replace(/\.$/, '')}in`;
console.log(`${path.basename(outPath)} — ${sheets.length} ${coverSpread ? 'spread' : 'sheets'}`
    + ` from ${path.basename(bookPath)}`
    + (coverSpread ? `, ${fmt(spreadW)} x ${fmt(sheet)} (2 x ${fmt(trim)} trim + ${fmt(bleed)} bleed, no spine)`
        : lulu ? `, ${fmt(trim)} square trim + ${fmt(bleed)} bleed, ${fmt(safe)} safety`
            + (padded ? `, ${padded} blank${padded > 1 ? 's' : ''} to reach a multiple of 4` : '')
        : board ? `, ${trim}mm square + ${bleed}mm bleed` : ', A5'));
