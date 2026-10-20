---
name: storybook
description: Take a children's book from an idea or a family's storyline to a ready-to-print PDF and a live link to share, end to end — interview the family, turn the storyline into a page plan, write the text (English + Egyptian or fusha Arabic), lock the main character, generate the artwork locally with Z-Image Turbo, build the HTML book, add it to the shelf, produce print PDFs (board edition and Lulu), narrate it, then commit, push and confirm the GitHub Pages link is live. Use when the user asks for a new story or book for a child, gives a storyline to turn into a book, wants an existing book's story changed, or wants one of these steps redone.
---

# Making a storybook

Worked examples: Yaseen's Big Year (a long, Egyptian-only book for a
four-year-old: `stories/yaseen.json`, `source/gen-yaseen.sh`) and Loza the Cat
(a short true story with fusha and Egyptian: `stories/loza.json`).

The order matters. Text and pictures are cheap to change before the batch
render (about 90s a picture at 1536px, so over an hour for a 45-page book, run
in the background) and expensive after it.

## The whole run, at a glance

| Step | You do | Script |
|---|---|---|
| 1 | Interview in one round; page plan approved | AskUserQuestion |
| 2–3 | Scaffold, then write the words in the spec | `tools/new-book.sh <slug> <Name> <الاسم> [--eg-only] [--long] [--no-svg]` |
| 4–5 | Lock the character in words; test seeds on 3–6 pages | `tools/try-seeds.sh <slug> <page> <seed> [n]` |
| 6 | Draw every page at 1536px; review; web copies | `DEST=$PWD/art-hi/images-<slug> zsh source/gen-<slug>.sh`, `tools/contact-sheet.py`, `tools/web-art.sh <slug>` |
| 7 | Build the book, shelf card, README; check in a browser | `zsh tools/build-<slug>.sh` |
| 8 | Print PDFs, all checks run | `tools/print-book.sh <slug> [--eg-only] [--long] [--lulu] [--back-art F]` |
| 9 | Narration | `~/Work/Elevenlabs-voice/generate.js` |
| 10 | Commit (when the user says), publish, confirm live | `tools/publish.sh <slug> "<phrase from the new text>"` |

**Pictures are always high resolution** (the user's standing rule): every page
is drawn once at 1536px, the web copy is that same picture shrunk to 1024px,
and both print editions use the 1536px master. Never enlarge a 1024px picture,
and never redraw a page at a new size: a new size is a new picture.

## 0. What "done" means

The job ends with three things handed to the user, not before:

1. **The live link**: `https://hisham-abuella.github.io/bedtime-stories/books/<slug>.html`,
   checked after the Pages deploy finishes (section 10), not just pushed.
2. **The print PDFs**, by path: `print/egyptian/<slug>-board-eg.pdf` (and
   `print/arabic/…` if fusha), plus `<slug>-lulu-interior*.pdf` and
   `<slug>-lulu-cover*.pdf` if they want a bound copy. Say which file goes where:
   board PDFs print at home on card; the Lulu pair is uploaded to Lulu as
   interior + cover.
3. **What's left**, if anything: narration not yet generated (quota), pictures
   the user should look at, a page they still need to approve.

Never stop at "pushed": the user will open the link straight away, and until the
deploy finishes it still shows the old book.

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
- Who appears in the pictures: the child (and pets) only; grown-ups are never drawn (section 5c).
- A photo of the child (or pet), to describe from.
- Print: board edition at home, Lulu hardcover, or screen only.

### Starting from a storyline the user gives you

Often the user pastes the story as a paragraph ("Loza was a very shy cat, from
the moment they got her from the shelter…"). Don't write pages straight from
it. First pull out:
- **Who is who.** A first name in their text (Khadija) may be someone the book
  calls Mama; ask, and use the book's word. Who did each thing (Mama *and Gedo*
  adopted her; Baba came later) decides which page says what.
- **The order of events**, and what replaces anything the old version had
  (Cairo → a San Diego shelter means the airplane page and Gedo's street go).
- **Hard parts** (they thought about giving her back; she bites): offer a
  gentle way to tell it in the same question round. For Loza: "everyone
  wondered if she'd be happier somewhere else, but Mama said no", and a funny
  "Chomp! Not there!" page.

Ask these together with the usual interview questions, in one round. Then map
each sentence of their storyline to a page and show the table.

Then **show the plan as a page table** (chapter · page · text idea · picture)
and wait for approval before writing. Adding a page is fine (Loza went from
10 to 11); the print tools pad and re-flow on their own. Ask before dropping
a page the family may love.

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
- Start from `tools/new-book.sh`, which writes a two-page spec skeleton, the
  art script and the build script with this book's flags.
- **Egyptian only**: set `ar` to a copy of `eg`, notes included, and pass
  `--eg-only` (the Arabic button opens مصري; no فصحى narration is written).
- Give the cover a `say` in all three languages.
- `<em>` is allowed inside `line` (used for transliterations like *gamed gedan*).

## 4. The local image model

All artwork is drawn on this Mac by **Z-Image Turbo** through
`/opt/homebrew/bin/draw-things-cli` (the Draw Things app's CLI). Nothing goes to
a cloud service, so a family's details stay here. Never fall back to hand-drawn
SVG for a new book; the pictures come from the model.

```sh
draw-things-cli models list --downloaded-only     # z_image_turbo_1.0_q8p.ckpt must be there
draw-things-cli generate --model z_image_turbo_1.0_q8p.ckpt \
  --prompt "…" --negative-prompt "…" --width 1536 --height 1536 --seed 600 --output x.png
```

- **About 90s a picture at 1536px**, one at a time (the GPU is shared, so never
  run two batches together). Long batches go in the background.
- **The seed is the picture.** The same prompt + seed + size gives the same
  picture again (checked: 3/255 at most, GPU noise). A different size or
  any change to the prompt, even a comma, gives a different picture.
- **Always 1536px** (the rule at the top). The 1024px web copy is shrunk from it.
- The model **cannot write**: any text comes out as nonsense, and Arabic
  worst. Keep `text, letters, words, numbers, arabic script, writing, signs,
  logo, label` in every negative prompt; ask for "a plain blank lunch box",
  not a lunch box (one came back reading "Hiro").
- **Style lives in one `STYLE` string** appended to every prompt, and the
  opposite styles go in the negatives, or pages wander between looks:
  - bright cartoon (Yaseen): `bold clean black outlines, flat vibrant colours,
    simple rounded shapes…`, negatives `painterly, gouache, watercolour
    texture, photorealistic, 3d render`
  - soft gouache (Loza, Susu, the Muslim books): `soft gouache, gentle rounded
    shapes, cosy, generous negative space, muted warm palette`
  - flat vector (the volume covers): `flat vector children's book
    illustration, bold simple geometric shapes, plain off-white paper background`
- Also in this Draw Things install: Qwen Image 2512. Nothing in this repo uses
  it; stay with Z-Image so every book matches.
- **What doesn't work, so don't spend time on it:**
  - *img2img as a character reference.* `--image` with `--strength` up to 0.85
    copies the reference's pose and scene; lower keeps the photo's realism
    (Susu's and Loza's covers were both tried from their photographs). The
    model has no reference-image input.
  - *Training a character LoRA.* `draw-things-cli train lora` accepts Z-Image
    in a dry run, but real training crashes at step 0 on this Mac
    (`Assertion failed … _ccv_nnc_swish_mul_back`, tried 2026-10-14). Try again
    only after a draw-things-cli update.

  So **the character is held by words alone**, which is the next section.

## 5. One character on every page

This is most of the visual quality. Yaseen's book (`source/gen-yaseen.sh`, 45
pages, the boy on every one) is the model to copy.

**a. Build the character from parts, as shell variables, and never retype them.**

```zsh
HAIR="jet-black hair, short and messy, with a soft fringe over his forehead and one little tuft sticking up on top"
BOY="a cheerful four-year-old cartoon boy with $HAIR, fair skin, round soft face, small thin eyebrows, round rosy cheeks"
YASEEN="$BOY, big dark brown eyes and a bright smile"          # the default page
ASLEEP="$BOY, fast asleep with both eyes shut as two curved lines, peaceful smile"
TEE="wearing a red t-shirt and blue jeans"                      # three fixed outfits
KIT="wearing a blue soccer jersey, white shorts, blue and white striped socks and black soccer boots"
PJS="wearing light blue pyjamas"
```

- **Feature by feature**: face shape, eyebrows (thin, or the model gives a
  thick-browed boy who is somebody else), cheeks, eyes, skin. Ask the family
  for a photo and describe it; don't feed the photo to the model.
- **Hair exactly**: colour, length, cut, fringe, one distinguishing detail
  (the tuft). Hair is the first thing to drift.
- **Expression is not part of the identity.** `$YASEEN` smiles; a worried or
  amazed page uses `$BOY` plus its own face ("$BOY, big dark brown eyes, a
  little worried face"), or the smile in `$YASEEN` fights the scene.
- **Asleep has its own variable without the eyes.** Naming eye colour makes the
  model paint an eye open (Loza's goodnight page did that).
- **Fixed outfits**, used by name. A new outfit is a new character to the model.
- **An animal is the same**: Loza is "a round-faced white cartoon cat with a
  fluffy white coat, odd eyes — her right eye pale blue and her left eye green
  — a small dark grey smudge on the very top of her head…", plus `KITTEN` and
  `SLEEPING` variants.
- **Recurring props get variables too**: `BABY` (the size rule below) and
  `TROLLEY`, the hidden object on every page.

**b. Negatives guard the identity**: everything the character must not become.
Yaseen's: `bob haircut, bowl cut, hair covering ears, brown hair, dark brown
hair, long hair, spiky hair, thick eyebrows, bushy eyebrows, crayon shin-chan,
girl`. Loza's: `tabby stripes, black cat`. Add one each time a drift shows up.

**c. Do not draw grown-ups.** Arms, laps and hugs came out mangled, with extra
arms. Parents, grandparents and coaches live in the words; show them by what
they leave (Baba's shoes by the door, the bowl Mama put out, a heart cushion, a
thought bubble). Negatives: `adult, grown-up, man, woman, adult arms, adult
hands, extra arms, extra hands`.

**d. A baby sibling is "a very tiny newborn baby girl, no bigger than a loaf of
bread and less than half the size of the boy"**, and the page asks for a "full
body view" of the big sibling. Without that, the baby came out bigger than him.

**e. Test before the batch.** Write the cover and 3–6 varied pages (outfits,
an expression page, asleep, the baby), try 3–4 seeds of each:

```sh
tools/try-seeds.sh <slug> <page> <first-seed> [count]   # build/<slug>-try/<page>-sheet.png
```

It uses the book's own prompt from `gen-<slug>.sh`. If the same drift shows on
every seed, change the words, not the seed. When the test pages agree, run the
whole book.

**f. Review every page on a contact sheet, then fix drift page by page.**

```sh
python3 tools/contact-sheet.py build/<slug>-sheet.png art-hi/images-<slug>/*.png
```

Check: same face, same hair colour and cut, right outfit, baby smaller than
the sibling, hidden object there, no text, no grown-ups, picture matches the
words, and **limbs counted on the full-size picture**. A waving animal sitting
down shows three paws on the ground: asked only to "wave", the model keeps all
four down and adds a fifth in the air, so say "lifts her right front leg, so
only her left front paw stays on the ground".

For a page that drifted:
1. Try new seeds first (`try-seeds.sh`). **Seed numbering records the history**:
   first draw 600–644, the first redraw +100 (7xx), then 8xx, 9xx.
2. If the drift survives new seeds, **repeat the slipping feature on that
   page**. Yaseen's hair kept growing into a bob on three pages, so those lines
   add "very short cropped boy's hair with ears showing" after `$YASEEN`
   (seeds 9213, 9233, 9445).
3. If it shows on many pages, fix the variable or the negatives and **redraw
   every page**, or the old pages won't match the new ones.

To swap in a chosen trial: copy `build/<slug>-try/<page>-<seed>.png` to
`art-hi/images-<slug>/<page>.png`, put that seed on the page's `gen` line, then
`tools/web-art.sh <slug> <page>`.

**g. Content rules** for the Muslim books (`source/gen-muslim-books.sh`): no
figure ever stands in for the Prophet ﷺ (show what he loved instead), and
the negatives carry `cross, church, statue, idol, pig, alcohol, revealing
clothing`. Keep `pig, alcohol, revealing clothing, bare shoulders` in every
book's negatives.

## 6. Drawing the book: `source/gen-<slug>.sh`

```sh
DEST=$PWD/art-hi/images-<slug> zsh source/gen-<slug>.sh   # run_in_background; skips existing PNGs
tools/web-art.sh <slug>                                     # images-<slug>/*.png, 1024px, for the web
```

- One `gen <page> "<prompt>" <seed>` line per page, in page order, with a
  comment above each chapter. A comment on any page that needed help says why
  (it's how the next person knows not to "simplify" it).
- The script skips pages that already exist, so it can be stopped and rerun.
- `art-hi/` is git-ignored (the masters are large and reproducible from their
  seeds); the print JPEGs made from them in `input/img-hi/` are committed.
- `gen-<slug>.sh` from `new-book.sh` already defaults to `SIZE=1536` and
  `DEST=art-hi/…`. Older books' scripts default to 1024: always pass
  `SIZE=1536` and `DEST=$PWD/art-hi/images-<slug>` to them.
- A back-cover picture (waving goodbye) is one more `gen` line, e.g. `print-back`.

## 7. Building the book: `tools/build-<slug>.sh`

```sh
zsh tools/build-<slug>.sh      # books/<slug>.html and source/<slug>-{en,ar,eg}.json
```

It runs `tools/build-book.py` with this book's flags. That fills the template
from the spec (`tools/new-story.js`), moves the book to `books/` with its paths
one directory up, puts the child's name where the template says Yusuf, and
writes the narration scripts. Flags: `--eg-only`, `--long` (40+ words a page:
side by side on wide screens, 18px+ type on a phone), `--no-svg` (pictures
only, no Artwork switch; the user's preference for new books), and
`--fallback-ar` for a nickname (Yaseen's is يَسّو).

**Always rebuild through the build script, never `new-story.js` alone.** A
bare run leaves a root-level book read to Yusuf with broken paths. Loza's book
was fixed by hand once and the next rebuild silently undid it.

Then add a card to `index.html` (copy Loza's `<article class="book">`) and a
section plus a table row to `README.md`. Keep the card's page count
(`<span class="fact">N pages</span>`) and blurb in step with the story.

**Check it in a browser**: `python3 -m http.server 8071 --bind 127.0.0.1`,
then Playwright screenshots at 1280×800 and 390×844. Look at a chapter opener,
the longest page, and the Arabic side. `document.documentElement.scrollWidth`
must equal the viewport width (no sideways scroll).

## 8. PDFs: `tools/print-book.sh`

```sh
tools/print-book.sh <slug> [--eg-only] [--long] [--lulu] [--back-art FILE] [--name N --name-ar N]
```

One command makes the QR code if it's missing (`tools/make-qr.py` covers every
book in `books/`), the print JPEGs from the 1536px masters, and the PDFs:

| File | What it's for |
|---|---|
| `print/egyptian/<slug>-board-eg.pdf` | 180mm square, printed at home on card |
| `print/arabic/<slug>-board.pdf` | the same with fusha (not with `--eg-only`) |
| `print/…/<slug>-lulu-interior[-eg].pdf` | `--lulu`: uploaded to Lulu as the interior |
| `print/…/<slug>-lulu-cover[-eg].pdf` | `--lulu`: uploaded as the cover (back + spine + front) |

Then it runs every check and stops on a failure:
- `check-print-text.py`: no words clipped off a page, and story type at least
  14pt English / 15pt Arabic. Don't judge type from a small preview; a 30–60dpi
  render makes 13.5pt look like 9pt.
- `check-lulu.sh`: Lulu's size, bleed, 300–600ppi, fonts and page rules.
- `check-qr.py <slug>`: every QR decodes and opens this book.

Options:
- `--long` for books written long (40+ words a page): a smaller picture so the
  type never drops below the floor. Leave it off for the baby books.
- `--lulu` needs **32+ pages** (perfect binding); the script refuses a shorter
  book. Short books are bound with others as a volume (`tools/build-volumes.sh`,
  `tools/build-noah.sh`), or printed as the board edition only.
- `--back-art`: draw a back-cover picture at 1536 (the child waving goodbye;
  Susu and Yaseen have one) and pass its `input/img-hi/…jpg`.
- `--name`: fixes the child's name on paper for a copy made for one child.

Books printed in a set have their own scripts that call the same tools:
`tools/build-noah.sh` (Noah's copies), `tools/build-volumes.sh` (the volumes),
`tools/build-yaseen-print.sh`.

**Keep the diff to what changed.** Set scripts rebuild every PDF in the set,
and Chrome writes new bytes even when nothing changed. Before committing,
`git checkout --` the PDFs of books you didn't touch.

## 9. Narration

```sh
zsh tools/build-<slug>.sh                                   # also rewrites source/<slug>-*.json
node ~/Work/Elevenlabs-voice/lint-transcript.js --pair source/<slug>-en.json source/<slug>-eg.json
node ~/Work/Elevenlabs-voice/generate.js source/<slug>-en.json audio-<slug>/en \
  --voice pusofH2Ro5Ny4RH6qBEO --model eleven_v4 --stability 0.5 --similarity 0.8
node ~/Work/Elevenlabs-voice/generate.js source/<slug>-eg.json audio-<slug>/eg \
  --voice IES4nrmZdUBHByLBde0P --model eleven_v4 --stability 0.5 --similarity 0.8
python3 ~/Work/Elevenlabs-voice/qa-audio.py source/<slug>-en.json audio-<slug>/en
```

- **Voices** (the house ones): English is Hisham's clone `pusofH2Ro5Ny4RH6qBEO`.
  Egyptian is **Haytham EG narrator** `IES4nrmZdUBHByLBde0P`. Sarah
  (`EXAVITQu4vr4xnSDxMaL`) is fusha.
- The narration scripts come from the spec, so rebuild before narrating and
  the clips match the words.
- **Give the cover a `say`** in the spec, or make-transcripts writes "for Yusuf".
- **Quota**: check `generate.js --usage` first. `eleven_v4` billed Yaseen's
  16k English characters at about 1.7k credits, so a whole book can fit in what
  looks too small. The usage counter lags; the API's refusal message gives the
  real balance. The starter plan can't overrun, so running until it refuses is
  safe. The generator skips clips that already exist, so rerun after the reset
  to finish.
- lint's "missing space after comma" before a closing quote (`Yasso,” said`)
  is a false alarm.
- QA medians: English 0.068–0.085, Arabic 0.089–0.104 seconds per character.

## 10. Publish and share: `tools/publish.sh`

The site is GitHub Pages from `main`; nothing builds on GitHub's side. **Commit
and push only when the user says so**; ask once the book is ready.

```sh
git add -A && git status --short       # only this book's files, its PDFs, index.html, README
git commit -m "…"                      # say what the story is now, not which files changed
tools/publish.sh <slug> "<a phrase from the new text>"
```

`publish.sh` refuses uncommitted work, pushes, waits for the Pages deploy for
that commit (about two minutes), and reads the live page back for the phrase.
It prints the link only when the new book is really live.

Hand over the link with a note that an old copy may be cached: Cmd+Shift+R on
a computer, or close and reopen the tab on a phone. The shelf is
`https://hisham-abuella.github.io/bedtime-stories/`. The QR codes in the
printed books point at these same URLs, so a printed copy always plays the
latest narration.

## Changing an existing book

Same steps, smaller scope. From Loza's rewrite (Cairo → shelter):
- Interview only about what's changing, in one round (section 1).
- Edit `stories/<slug>.json` and `source/gen-<slug>.sh` (comment what each new
  picture shows and why). Draw new pages as 3–4 seeds each at 1536, pick one
  that matches the existing pages (for Loza: blue eye on the viewer's left),
  then `tools/web-art.sh <slug> <new-page> …`. **Name the pages** on books
  drawn before the 1536 rule (Loza, Susu, the Muslim books): their `art-hi/`
  masters are separate re-renders, not the web pictures, and a bare
  `web-art.sh <slug>` would swap every page for a slightly different one.
- Pictures for dropped pages: `git rm` them from `images-<slug>/`,
  `input/img/`, `input/img-hi/`, and delete them from `art-hi/`.
- A book with a drawn SVG set (`stories/<slug>.art.js`, Loza and the Muslim
  books) needs a simple drawing for each new page, or the Artwork switch
  shows blank pages. Check them in the browser; the first try is usually too rough.
- Search for the old story everywhere: `git grep -n "Cairo" -- books/<slug>.html
  stories/<slug>* source/<slug>* index.html README.md`.
- `zsh tools/build-<slug>.sh`, then the PDFs (`tools/print-book.sh`, or the
  set script the book belongs to); regenerate narration only if the book has
  audio (`ls audio-<slug>`).

## Checklist

- [ ] Interview answered in one round; page plan approved
- [ ] Spec written; nicknames and family phrases in dialogue; notes on every page
- [ ] Character, hair, outfits and baby size locked; 3–6 test pages approved
- [ ] All pages drawn at 1536px and reviewed on contact sheets; off-model pages redrawn; `web-art.sh` run
- [ ] Built, on the shelf, in the README; checked on desktop and phone
- [ ] `print-book.sh` ends with "all checks passed" (text, Lulu, QR); 18px+ on a phone
- [ ] Narration in the house voices, QA clean, every page present
- [ ] Unrelated PDFs reverted; committed and pushed (when the user says so)
- [ ] `publish.sh` printed the live link; link and PDF paths handed over (section 0)
