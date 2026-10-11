#!/usr/bin/env node
/**
 * Build a story book from a spec.
 *
 *   node tools/new-story.js stories/<slug>.json
 *
 * The books are all the same machine: one HTML file, bilingual, two sets of
 * artwork, a clip per page. Only the pages differ. tools/story-template.html is
 * that machine with the Susu-shaped holes left open; this fills them.
 *
 * A spec holds the words. The drawings live beside it in stories/<slug>.art.js,
 * which is plain JavaScript assigning into ART, so a drawing can be edited
 * without going through this script.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const specPath = process.argv[2];
if (!specPath) {
    console.error('usage: new-story.js stories/<slug>.json');
    process.exit(1);
}
const root = path.join(__dirname, '..');
const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
const slug = spec.slug;
const dir = path.dirname(specPath);
const shapesPath = path.join(dir, '_shapes.js');
const artPath = path.join(dir, `${slug}.art.js`);
const shapes = fs.existsSync(shapesPath) ? fs.readFileSync(shapesPath, 'utf8') : '';
const own = fs.existsSync(artPath) ? fs.readFileSync(artPath, 'utf8') : '';
if (!own) console.warn(`! no ${artPath} — pages will have no drawn fallback`);
const art = [shapes, own].filter(Boolean).join('\n\n');

const q = (s) => "'" + String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "'";

// ---- the BOOK object --------------------------------------------------------
const pages = spec.pages.map((p, i) => {
    const side = (lang) => {
        const c = p[lang];
        const bits = p.cover
            ? [`eyebrow:${q(c.eyebrow)}`, `title:${q(c.title)}`, `line:${q(c.line)}`, `note:${q(c.note)}`]
            : [`name:${q(c.name)}`, `line:${q(c.line)}`, `sound:${q(c.sound)}`, `note:${q(c.note)}`]
                .concat(c.chapter ? [`chapter:${q(c.chapter)}`] : []);
        return `${lang}:{ ${bits.join(',\n               ')} }`;
    };
    const head = [`art:ART[${q(p.key)}]`, p.cover ? 'cover:true' : null, `audio:'p${i}'`,
                  p.tint ? `tint:${q(p.tint)}` : null].filter(Boolean).join(', ');
    return `      P({ ${head},\n          ${side('en')},\n          ${side('ar')} })`;
});

const BOOK = `var BOOK = {
  ${slug}: {
    accent: ${q(spec.accent)},
    pages: [
${pages.join(',\n\n')}
    ]
  }
};`;

// ---- where the audio and the generated artwork live -------------------------
// Egyptian Arabic: only the story words are given in the spec; anything else
// (the grown-up notes) falls back to the فصحى page in the book itself.
const eg = spec.pages.map((p) => {
    const { say, ...words } = p.eg || {};
    return words;
});

const WIRING = `// Egyptian Arabic: the story words in مصري. Anything not given here (the
// grown-up notes) falls back to the فصحى page.
var EG = { ${slug}: ${JSON.stringify(eg, null, 1)} };
Object.keys(EG).forEach(function (k) {
  BOOK[k].pages.forEach(function (pg, i) { pg.eg = Object.assign({}, pg.ar, EG[k][i]); });
});

var AUDIO_DIR = { ${slug}:{ en:'audio-${slug}/en/', ar:'audio-${slug}/ar/', eg:'audio-${slug}/eg/' } };
var SFX_DIR   = {};

var IMG_V1 = {
  ${slug}: [${spec.pages.map((p) => q(p.img || p.key)).join(', ')}]
};
['${slug}'].forEach(function (k) {
  BOOK[k].pages.forEach(function (pg, i) {
    pg.img = 'images-${slug}/' + IMG_V1[k][i] + '.png';
  });
});`;

const icon = encodeURIComponent(spec.icon).replace(/%/g, '%25').replace(/%25/g, '%');

let out = fs.readFileSync(path.join(root, 'tools/story-template.html'), 'utf8');
const fill = {
    TITLE: spec.title, DESC: spec.desc, OGDESC: spec.ogdesc || spec.desc,
    ICON: encodeURIComponent(spec.icon),
    SIBLING_LINK: '', SIBLING_EN: '', SIBLING_AR: '',
    SOUND_EN: '', SOUND_AR: '',
    ART: art.trim(), BOOK, WIRING, SLUG: slug,
};
for (const [k, v] of Object.entries(fill)) out = out.split(`{{${k}}}`).join(v);

const left = out.match(/\{\{[A-Z_]+\}\}/g);
if (left) { console.error('unfilled placeholders:', left); process.exit(1); }

const dest = path.join(root, `${slug}.html`);
fs.writeFileSync(dest, out);
console.log(`${slug}.html — ${spec.pages.length} pages`);
