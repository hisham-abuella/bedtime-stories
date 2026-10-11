#!/usr/bin/env node
/**
 * Draft the narration transcripts for a story from its spec.
 *
 *   node tools/make-transcripts.js stories/<slug>.json
 *
 * Writes source/<slug>-{en,ar,eg}.json in the format
 * generate.js expects. The words come from the spec, so the narration cannot
 * drift from the printed page; the delivery is added here as v4 audio tags.
 *
 * Opening tag per page can be set in the spec as "tag" / "tagAr"; the default
 * is [warmly], and the last page whispers.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const specPath = process.argv[2];
if (!specPath) { console.error('usage: make-transcripts.js stories/<slug>.json'); process.exit(1); }
const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
const root = path.join(__dirname, '..');

// the page markup is for the eye; the model gets plain words
const plain = (s) => String(s || '')
    .replace(/<br\s*\/?>/gi, ' ')
    .replace(/<[^>]+>/g, '')
    .replace(/\s{2,}/g, ' ')
    .trim();

function build(lang) {
    const slides = spec.pages.map((p, i) => {
        // eg gives only the story words; the rest comes from the فصحى page
        const c = lang === 'eg' ? { ...p.ar, ...p.eg } : p[lang];
        const last = i === spec.pages.length - 1;
        const open = p.tag || (last ? '[softly]' : '[warmly]');
        let body;
        if (p.cover) {
            // a cover whose eyebrow is not a phrase that fits the sentence can
            // give its own opening line in the spec
            if (c.say) return { id: `p${i}`, title: plain(c.eyebrow), transcript: c.say };
            const title = plain(c.title);
            const forWhom = { en: 'for Yusuf', ar: 'ليوسف', eg: 'عشان يوسف' }[lang];
            const comma = lang === 'en' ? ',' : '،';   // Arabic takes its own comma
            body = `${open} ${title}. ${plain(c.eyebrow)}${comma} ${forWhom}. <break time="0.5s" /> [gently] ${plain(c.line)}`;
        } else {
            const refrain = plain(c.sound);
            const close = last ? '[whispers]' : '[softly]';
            // a heading that already ends in ! or ? keeps its own punctuation
            const name = plain(c.name), stop = /[.!?…؟]$/.test(name) ? '' : '.';
            body = `${open} ${name}${stop} <break time="0.4s" /> ${plain(c.line)} <break time="0.5s" /> ${close} ${refrain}`;
        }
        return { id: `p${i}`, title: plain(c.name || c.eyebrow), transcript: body };
    });
    return { title: `${spec.title} ${lang.toUpperCase()}`, language: lang, slides };
}

for (const lang of ['en', 'ar', 'eg']) {
    const out = path.join(root, 'source', `${spec.slug}-${lang}.json`);
    fs.writeFileSync(out, JSON.stringify(build(lang), null, 1) + '\n');
    const chars = build(lang).slides.reduce((n, s) => n + s.transcript.length, 0);
    console.log(`source/${spec.slug}-${lang}.json — ${spec.pages.length} slides, ${chars} characters`);
}
