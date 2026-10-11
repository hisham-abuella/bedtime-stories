---
name: storybook
description: Make a new personalised children's storybook in this repo, end to end — interview the family, plan chapters and pages, write the text (English + Egyptian or fusha Arabic), lock the main character, generate the artwork locally with Z-Image Turbo, build the HTML book, add it to the shelf, and produce print PDFs (board edition and Lulu). Use when the user asks for a new story or book for a child, or to redo one of these steps for an existing book.
---

# Making a storybook

Worked example: Yaseen's Big Year (`stories/yaseen.json`, `source/gen-yaseen.sh`,
`tools/build-yaseen.sh`). Copy those three files when you start, rather than
starting from scratch.

The order matters. Text and pictures are cheap to change before the batch
render (about 40s a picture, 30 minutes for a 45-page book) and expensive after it.

## 1. Interview: ask everything up front, in one round

On Yaseen's book, the details arrived one message at a time: city, preschool,
Del Mar, nickname, Egyptian only, a family phrase. Every late detail meant
rewriting pages or redrawing pictures. So ask these together, with
AskUserQuestion (several questions per call) plus one free-text message:

**The child**
- Name, age, and **nicknames by who uses them** (Baba calls him *Yasso*).
- What they look like: hair colour and style, skin tone, eye colour. A photo helps.
- Family words and catch-phrases (*gamed gedan* = جامد جدًا, *ata3 el shabaka* = قطّع الشبكة).
- What the parents are called (Mama/Baba?), and siblings' names. "Little sister" is fine.

**Their world**
- City, and real places they love (Del Mar, where the trains run along the cliffs).
- What they love (soccer, trains, books), and what they're good at.
- What's happening this year: starting school, a new sibling, a move, a trip.
- Team or kit colours, a favourite toy, a favourite food.

**The book**
- Length: pages, and chapters if the book runs past about 20 pages.
- Languages: English plus **Egyptian only**, **fusha only**, or both.
- How Islamic: a light touch (Bismillah, Alhamdulillah) or more.
- Art style: bright cartoon (Yaseen) or soft gouache (Loza and Susu).
- Who appears in the pictures: the child only, or others too (see rule 4b).
- Print: board edition at home, Lulu hardcover, or screen only.

Then **show the plan as a page table** (chapter · page · text idea · picture)
and wait for approval before writing.

## 2. Writing for the age

| Age | Words/page | Shape |
|---|---|---|
| 0–1 | 1–15 | one idea, one refrain, high contrast |
| 2–3 | 10–30 | refrain plus a sound word |
| 4–5 | 40–70 | small scenes, dialogue, callbacks, chapters of 5–9 pages |

What worked at 4:
- **Refrains and sound words** the child can shout: *ding-ding*, *tweeet*, *tap-tap-tap*, *BEEP BEEP*, *soft hands, slow hands, gentle hands*.
- **A hidden object on every page** (the red trolley, like the zoo's red bird).
- **Threads that pay off later**: practising with the teddy pays off when he holds the baby. Being new at preschool is why he's kind to the new boy, and later to his sister.
- **Model safety quietly**: stand far back behind the fence at the tracks, sit down with a cushion to hold a baby.
- **For a new sibling**: a "Will you still love me?" page ("love gets bigger") and a "Yaseen time" page. These matter more than any plot.
- **Grown-up notes** on every page, in both languages: one or two practical sentences.
- Put the child's name and nickname in **dialogue**, not just narration.

## 3. The spec: `stories/<slug>.json`

The spec is the only source of the words. The page, the print edition and the
narration all read it.

- Page fields: `key` (also the image name), `img`, `tint`, and `en` / `ar` / `eg`
  with `name`, `line`, `sound`, `note`. The cover uses `eyebrow`, `title`
  (`<br>` and `<em>` allowed), `line`, `note`.
- `chapter` on the first page of each chapter puts the chapter name above the heading.
- **Egyptian only**: set `ar` to a copy of `eg`, notes included, and drop the
  dialect switch in the build script, as Yaseen's does.
- `<em>` is allowed inside `line` (used for transliterations like *gamed gedan*).

## 4. Locking the character (most of the visual quality)

a. **Pin everything about the main character down in words, and reuse it
   verbatim** in every prompt:
   - Face, feature by feature: `round soft face, small thin eyebrows, round rosy cheeks, big dark brown eyes`.
   - **Hair, exactly**: `jet-black hair, short and messy, with a soft fringe over his forehead and one little tuft sticking up on top`.
   - Three fixed outfits as variables: `TEE`, `KIT`, `PJS`.
   - A separate `ASLEEP` description with no eyes in it, or the model paints them open.

   Left looser, the model drifts: thick eyebrows and a "Shin-chan" face, brown hair, a girl's haircut.

b. **Do not draw grown-ups.** Arms, laps and hugs came out mangled, with extra
   arms. Parents and coaches live in the words. Show their love through props:
   a heart cushion, hearts, a thought bubble.

c. **The baby is "a very tiny newborn baby girl, no bigger than a loaf of
   bread and less than half the size of the boy"**, and the page asks for a
   "full body view" of the big sibling. Without that, the baby came out bigger than him.

d. Negative prompt essentials: `brown hair, long hair, thick eyebrows, crayon
   shin-chan, girl, adult, grown-up, adult arms, extra arms, text, letters,
   words, numbers, label, logo, arabic script`. Text has to stay out, because
   a snack box came back reading "Hiro".

e. **img2img is not a character reference.** `--image` with `--strength` up to
   0.85 copies the reference's pose and scene. The local models (Z-Image Turbo,
   Qwen Image) have no reference input, so consistency comes from the words.

f. **Test before the batch**: render 3–6 pages into `build/<slug>-test/`
   (`DEST=... zsh test.sh` with just those `gen` lines) and look at them side
   by side. Only then run all of them.

## 5. Generating the artwork: `source/gen-<slug>.sh`

```sh
zsh source/gen-<slug>.sh            # run_in_background; skips existing PNGs
```

- One `gen key "prompt" seed` line per page, with seeds in a block (600–644).
- **Review with contact sheets** (a 4-column grid, PIL, 300px tiles, the key
  above each). Check every page for: same face, same hair colour and cut,
  right outfit, baby smaller than the sibling, the hidden object there, no
  text, no adults, the picture matches the words.
- **To redraw a page**: move its PNG to `build/<slug>-old/`, change that
  line's seed or prompt, and rerun the script (it only draws what's missing).
- After a change to the character description, **redraw everything**, or the
  old pages won't match.

## 6. Building the book: `tools/build-<slug>.sh`

`tools/new-story.js` fills `tools/story-template.html` from the spec and writes
`<slug>.html` at the repo root. The build script then:
- moves it to `books/` and rewrites paths to `../images-<slug>/` and `../audio-<slug>/`
- swaps the template's Yusuf for the child's name (placeholder, fallback, dedication)
- Egyptian only: renames the Arabic button مصري and removes the فصحى/مصري switch
- long pages (40+ words): a side-by-side layout above 900px wide
- **no SVG** (user preference): hides the Artwork switch and has no
  `stories/<slug>.art.js`; a missing picture shows a blank tint

Then add a card to `index.html` (copy Loza's `<article class="book">`) and a
section plus a table row to `README.md`.

**Check it in a browser**: `python3 -m http.server 8071 --bind 127.0.0.1`,
then Playwright screenshots at 1280×800 and 390×844. Look at a chapter opener,
the longest page, and the Arabic side. `document.documentElement.scrollWidth`
must equal the viewport width (no sideways scroll).

## 7. PDFs

```sh
python3 tools/make-qr.py     # add 'qr-<slug>' to CODES first; needs segno (uvx --with segno python …)
```

**Board edition** (180mm square, printed at home on card): add the slug to the
`jpegs()` list and the `for pair in …` list in `tools/build-print.sh`, or run
the two steps directly:

```sh
mkdir -p input/img/images-<slug>
for p in images-<slug>/*.png; do sips -s format jpeg -s formatOptions 88 "$p" --out input/img/images-<slug>/$(basename ${p%.png}).jpg; done
node tools/make-print.js books/<slug>.html build/<slug>-board-eg.html \
  --url https://hisham-abuella.github.io/bedtime-stories/books/<slug>.html \
  --qr input/qr/qr-<slug>.svg --board --art images --dialect eg
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-pdf-header-footer \
  --print-to-pdf=print/egyptian/<slug>-board-eg.pdf "file://$PWD/build/<slug>-board-eg.html"
```

**Lulu** (8.5in square, perfect bound, 32+ pages and a multiple of 4): this
needs 1536px artwork first, `DEST=$PWD/art-hi/images-<slug> SIZE=1536 zsh source/gen-<slug>.sh`,
about 1 hour. Same seeds give the same compositions. Then follow
`tools/build-noah.sh` for the `--lulu` interior plus the `--cover` spread, and
run `tools/check-lulu.sh` and `tools/check-qr.py`. Run the overflow check from
the README on every edition, because long pages get clipped without warning.

## 8. Narration (optional)

`node tools/make-transcripts.js stories/<slug>.json` writes
`source/<slug>-{en,ar,eg}.json`; then follow "Adding a story" in the README
(ElevenLabs, or `~/Work/AI_server/scripts/voiceover.py` locally). Until
`audio-<slug>/` exists, "Read to me" has nothing to play.

## Checklist

- [ ] Interview answered in one round; page plan approved
- [ ] Spec written; nicknames and family phrases in dialogue; notes on every page
- [ ] Character, hair, outfits and baby size locked; 3–6 test pages approved
- [ ] All pages rendered and reviewed on contact sheets; off-model pages redrawn
- [ ] Built, on the shelf, in the README; checked on desktop and phone
- [ ] QR code, board PDF; Lulu PDFs if wanted (1536px art)
- [ ] Narration, if wanted
