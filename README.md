# Bedtime Stories

Board books made for Yusuf, matched to what he can see and hear at each age.
Each story is one self-contained HTML file plus a folder of narration audio —
no framework, no build step. Open `index.html` for the shelf.

| Story | File | Age it was made for |
| --- | --- | --- |
| The Black and White Zoo | `black-white-zoo.html` | 3 months |
| Susu the Cat | `susu.html` | 3 months |

## The Black and White Zoo

Two chapters, 11 pages each, English and Arabic.

- **Black & White** — zebra, panda, cow, penguin, owl, orca, sheep, puppy, cat,
  goodnight moon. Maximum contrast, because that is what a newborn resolves best.
- **Colours** — red, yellow, blue, green, orange, purple, pink, brown, grey, rainbow.
  Introduced in the order infant colour vision develops; heavy black outlines keep the
  contrast working.

A red bird hides in a different corner of every animal page — red is the first colour
a baby can pick out. Nine hiding places.

## Susu the Cat

The true story of Susu — adopted in Oklahoma during the PhD, the drive to California,
then Mama, then Yusuf. Ten pages, deliberately undated: the shape is *then, and then,
and then*.

One page carries the hadith of the woman punished over a cat she imprisoned without
food or water (Bukhari 3318, Muslim 2242). The child-facing wording is gentle; the full
narration and its sources sit in the grown-up note on that page, beside the hadith of
the thirsty dog.

## Two sets of artwork

The top bar has an **Artwork** switch:

- **drawn** — hand-written SVG, inline in the page. The right one for a newborn.
- **illustrated** — generated images in `images-v1/` and `images-susu/`, made locally
  with `draw-things-cli` (Z-Image Turbo, 1024×1024). Prompts and seeds in
  `source/gen-pages.sh` and `source/gen-susu.sh`.

The zoo opens on *drawn*, Susu on *illustrated*. A page whose image is missing falls
back to the drawing, so the switch is safe while a batch is still rendering.

## Audio

| Folder | Contents | Voice |
| --- | --- | --- |
| `audio/en`, `audio/ar` | Zoo, black & white pages | Hisham (cloned) / Sarah |
| `audio/cen`, `audio/car` | Zoo, colour pages | Hisham (cloned) / Sarah |
| `audio/ens`, `audio/ars`, `audio/cens`, `audio/cars` | Animal sounds | Hisham / Sarah |
| `audio-susu/en`, `audio-susu/ar` | Susu pages | Hisham (cloned) / Sarah |
| `audio-susu/ens`, `audio-susu/ars` | Mew, purr, meow | Hisham / Sarah |

Voice ids: Hisham `pusofH2Ro5Ny4RH6qBEO`, Sarah `EXAVITQu4vr4xnSDxMaL`.
Model: **`eleven_v4`**, delivery written into the transcripts as audio tags.

## Adding a story

1. Copy `susu.html` as a starting point — page data lives in the `BOOK` object near
   the bottom, artwork in the `ART` map above it.
2. Write the transcripts into `source/` — one file per language, same `id` set in both.
3. Lint, generate, check:

   ```sh
   node ~/Work/Elevenlabs-voice/lint-transcript.js --pair source/new-en.json source/new-ar.json
   node ~/Work/Elevenlabs-voice/generate.js source/new-en.json audio-new/en \
     --voice pusofH2Ro5Ny4RH6qBEO --model eleven_v4 --stability 0.5 --similarity 0.8
   python3 ~/Work/Elevenlabs-voice/qa-audio.py source/new-en.json audio-new/en
   ```

4. Add the book to the shelf in `index.html` and the table above.

Full guidance, including the Arabic rules and what breaks: `~/.claude/skills/elevenlabs-audio.md`.
To render locally instead of through ElevenLabs: `~/Work/AI_server/scripts/voiceover.py`.

## Where these are published

The copies served at **www.hishamabuella.com/projects/bedtime-stories/** live in the
`home` website repo. This repo is the place to author and keep them; copy a finished
story across when it is ready.
