#!/bin/zsh
DEST=${DEST:-/Users/hishamabuella/Work/personal_website/home/projects/bedtime-stories/images-susu}
SIZE=${SIZE:-1024}
mkdir -p "$DEST"
# Her cover is drawn from her real photograph, which lives in the repo so this
# script keeps working after any scratch directory is cleared.
REPO=$(cd "$(dirname "$0")/.." && pwd)
REF=${REF:-$REPO/images/susu-photo.jpg}
CLI=/opt/homebrew/bin/draw-things-cli
SUSU="a brown and grey mackerel tabby cat with a white chest, four white paws, a pink nose and green eyes"
STYLE="warm children's picture book illustration, soft gouache, gentle rounded shapes, cosy, generous negative space, muted warm palette"
NEG="text, letters, words, watermark, signature, people, human faces, human hands, photorealistic, cluttered, deformed, extra limbs, extra tails, blurry"

gen () {
  [[ -f "$DEST/$1.png" ]] && { echo "skip $1"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$2" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$3" \
    --output "$DEST/$1.png" >/dev/null 2>&1 && echo "done $1" || echo "FAIL $1"
}

# The cover is still taken from her real photograph ($REF) — the pose and the
# light below are described from it — but drawn rather than traced. Z-Image
# Turbo's img2img reproduces a photograph almost exactly at any strength worth
# using, which left a photographic cover on a book of gouache illustrations.
gen cover "portrait of $SUSU lying on her side in a warm patch of afternoon sunlight on a soft cream carpet, eyes half open, one ear lit from behind, $STYLE" 301

gen oklahoma   "$SUSU as a small kitten sitting beside a stack of books, a snowy window behind, $STYLE" 302
gen desk       "$SUSU curled asleep on a desk full of papers beside a glowing lamp at night, $STYLE" 303
gen drive      "$SUSU looking out of a soft travel carrier, a long highway and mountains behind, $STYLE" 304
gen california "$SUSU curled up on a wide sunny window sill, California light, $STYLE" 305
gen mama       "$SUSU sitting beside a teapot and two cups on a kitchen table, $STYLE" 306
gen baby       "$SUSU sitting calmly beside a baby's wooden crib, keeping watch, $STYLE" 307
gen days       "$SUSU stretching happily in a warm sunbeam, $STYLE" 308
gen kindness   "$SUSU eating from a full food bowl beside a full bowl of water, $STYLE" 309
gen goodnight  "$SUSU asleep curled at the end of a bed, a crescent moon and stars in the window, $STYLE" 310

# The covers of Yusuf's "Animals and Colours" volume: Susu with the zoo's
# zebra, panda and penguin on the front, and waving goodbye on the back. Flat
# vector rather than gouache, so she sits beside the zoo's black-and-white
# animals as one picture. Her description here is taken from her photographs
# (images/susu-photo*.jpg): darker than the gouache pages, with the white V up
# her face. "Exactly four legs" and the extra-limb negatives are there because
# the first front cover gave her an extra paw. Always 1536px: print only.
# Run with DEST=$PWD/images-susu — this script's DEST defaults to the website repo.
SUSU_REAL="a dark brown-grey tabby cat with bold black stripes, a white muzzle and a white upside-down V running up between her eyes, a big bright white bib covering her chest and belly down the middle of her front, white paws, pale green eyes, a pink nose and big ears, exactly four legs"
VEC="flat vector children's book illustration, bold simple geometric shapes, thick solid shapes, centered, plain off-white paper background, high contrast, minimal, generous negative space"
NEG="extra legs, extra paws, extra arms, extra hands, extra flippers, three front legs, five legs, all-dark chest, $NEG, light brown cat, orange cat, numbers"
SIZE=1536 gen vol-front "a zebra, a panda and a penguin standing together in black and white, each with exactly two arms or flippers, and $SUSU_REAL sitting in front of them facing the viewer, one small red bird, $VEC" 615
# Waving: the raised paw must be one of her two front legs. Asked only to
# "wave", the model kept both front paws down and added a third in the air;
# count the paws on the ground (three: one front, two back).
SIZE=1536 gen vol-back  "a dark brown-grey tabby cat with bold black stripes, a white muzzle and a white upside-down V running up between her eyes, a white chest, white paws, pale green eyes, a pink nose and big ears sitting upright, waving goodbye: she lifts her right front leg high in the air, so only her left front paw stays on the ground, she has only two front legs in total, a gentle smile, $VEC" 521
echo "SUSU IMAGES DONE"
