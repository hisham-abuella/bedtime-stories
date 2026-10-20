#!/usr/bin/env bash
# Start a new book: the three files every book needs, ready to fill in.
#
#   tools/new-book.sh <slug> <Name> <الاسم> [--eg-only] [--long] [--no-svg]
#
#   stories/<slug>.json     the words — the only source; page, print and voice read it
#   source/gen-<slug>.sh    the pictures — one gen line per page, drawn at 1536px
#   tools/build-<slug>.sh   the build — tools/build-book.py with this book's flags
#
# Then follow .claude/skills/storybook/SKILL.md from section 3.
set -euo pipefail
cd "$(dirname "$0")/.."
slug=${1:?usage: tools/new-book.sh <slug> <Name> <الاسم> [--eg-only] [--long] [--no-svg]}
name=${2:?child name}; name_ar=${3:?child name in Arabic}; shift 3
flags="$*"
for f in "stories/$slug.json" "source/gen-$slug.sh" "tools/build-$slug.sh"; do
  [[ -e $f ]] && { echo "new-book: $f already exists" >&2; exit 1; }
done

cat > "stories/$slug.json" <<JSON
{
  "slug": "$slug",
  "title": "TITLE",
  "icon": "📖",
  "accent": "#4F86A8",
  "desc": "One sentence for the shelf and search results.",
  "ogdesc": "One sentence for a shared link's preview.",
  "pages": [
    {
      "key": "cover", "img": "cover", "cover": true, "tint": "#BFD4DE",
      "en": { "eyebrow": "A story for $name", "title": "TITLE", "line": "One line under the title.",
              "note": "A grown-up note: one or two practical sentences.",
              "say": "[warmly] TITLE. A story for $name." },
      "ar": { "eyebrow": "", "title": "", "line": "", "note": "", "say": "" },
      "eg": { "eyebrow": "", "title": "", "line": "", "say": "" }
    },
    {
      "key": "first", "img": "first", "tint": "#E8C27A",
      "en": { "name": "Page name", "line": "The story text.", "sound": "A refrain to shout!", "note": "A grown-up note." },
      "ar": { "name": "", "line": "", "sound": "", "note": "" },
      "eg": { "name": "", "line": "", "sound": "" }
    }
  ]
}
JSON

cat > "source/gen-$slug.sh" <<'GEN'
#!/bin/zsh
# Artwork for SLUG, drawn locally by Z-Image Turbo — always at 1536px.
#
#   DEST=$PWD/art-hi/images-SLUG zsh source/gen-SLUG.sh    # run_in_background
#   tools/web-art.sh SLUG                                   # 1024px web copies
#
# The main character is pinned down in words once and reused verbatim in every
# prompt (skill section 5). No grown-ups are drawn: they live in the words.
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=${DEST:-$REPO/art-hi/images-SLUG}
SIZE=${SIZE:-1536}
mkdir -p "$DEST"
CLI=/opt/homebrew/bin/draw-things-cli
# The character, in parts (skill section 5). Never retype these in a prompt.
HAIR="HAIR EXACTLY: colour, length, cut, fringe, one distinguishing detail"
CHILD="a cheerful AGE-year-old cartoon CHILD with $HAIR, SKIN, round soft face, small thin eyebrows, round rosy cheeks"
HERO="$CHILD, EYE COLOUR eyes and a bright smile"       # default page; other moods use $CHILD + a face
ASLEEP="$CHILD, fast asleep with both eyes shut as two curved lines, peaceful smile"
TEE="wearing OUTFIT ONE"                                 # fixed outfits, used by name
PJS="wearing PYJAMAS"
HIDDEN="a tiny HIDDEN OBJECT hidden somewhere in the corner of the scene"
STYLE="bright cartoon children's book illustration, bold clean black outlines, flat vibrant colours, simple rounded shapes, big expressive eyes, playful and cheerful, plain uncluttered background"
# What the character must not become, grown-ups, text, and the house rules.
NEG="WRONG HAIR, thick eyebrows, bushy eyebrows, adult, grown-up, man, woman, adult arms, adult hands, extra arms, extra hands, extra fingers, extra limbs, deformed hands, photorealistic, photograph, 3d render, painterly, gouache, text, letters, words, numbers, arabic script, writing, signs, logo, label, watermark, crowd, cluttered, scary, blurry, cross, church, pig, alcohol, revealing clothing, bare shoulders"

gen () {   # gen <key> "<prompt>" <seed>
  [[ -f "$DEST/$1.png" ]] && { echo "skip $1"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$2" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$3" \
    --output "$DEST/$1.png" >/dev/null 2>&1 && echo "done $1" || echo "FAIL $1"
}

# Seeds: first draw 600 up in page order; a redraw adds 100 (7xx, 8xx, 9xx).
gen cover "$HERO $TEE, facing the viewer and waving, $STYLE" 600
gen first "$HERO $TEE, …, $HIDDEN, $STYLE" 601
echo "SLUG IMAGES DONE"
GEN
sed -i '' "s/SLUG/$slug/g" "source/gen-$slug.sh"

cat > "tools/build-$slug.sh" <<SH
#!/bin/zsh
# Build books/$slug.html from stories/$slug.json, read to $name.
exec python3 "\$(dirname "\$0")/build-book.py" $slug --name $name --name-ar $name_ar $flags
SH
chmod +x "source/gen-$slug.sh" "tools/build-$slug.sh"
printf 'made:\n  stories/%s.json\n  source/gen-%s.sh\n  tools/build-%s.sh\n' "$slug" "$slug" "$slug"
