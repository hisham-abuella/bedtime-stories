#!/bin/zsh
# Artwork for Loza the Cat, drawn locally by Z-Image Turbo.
# Same rules as Susu's book: the cat is the only character on the page, so no
# faces are invented for real people — Gedo, Baba, Mama and Noah are told by
# the words and shown by what they leave behind (a scarf, a suitcase, a crib).
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=${DEST:-$REPO/images-loza}
SIZE=${SIZE:-1024}
mkdir -p "$DEST"
# Her cover is drawn from her real photograph, kept in the repo.
REF=${REF:-$REPO/images/loza-photo.jpg}
CLI=/opt/homebrew/bin/draw-things-cli
LOZA="a slender pure white short-haired cat with odd eyes, her right eye pale blue and her left eye green, a small smudge of dark grey fur on the top of her forehead between the ears, pink ears and a pink nose"
KITTEN="a tiny pure white kitten with odd eyes, one pale blue and one green, a small smudge of dark grey fur on the top of her forehead, pink ears and a pink nose"
STYLE="warm children's picture book illustration, soft gouache, gentle rounded shapes, cosy, generous negative space, muted warm palette"
NEG="text, letters, words, numbers, arabic script, writing, signs, watermark, signature, people, human faces, human hands, photorealistic, cluttered, deformed, extra limbs, extra tails, blurry, tabby stripes, black cat"

gen () {
  [[ -f "$DEST/$1.png" ]] && { echo "skip $1"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$2" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$3" \
    --output "$DEST/$1.png" >/dev/null 2>&1 && echo "done $1" || echo "FAIL $1"
}

# The cover was tried as img2img from her photo (images/loza-photo.jpg), but
# Z-Image keeps the photo's realism at any strength that keeps her likeness, so
# it is drawn from the description like every other page.
gen cover     "portrait of $LOZA with a clear dark grey patch on her forehead, peeking out of a soft round grey felt cat cave bed, $STYLE" 411

gen cairo     "$KITTEN with a clear dark grey patch on her forehead, sitting alone on old stone steps in a quiet Cairo street at dusk, sandy buildings, a minaret and palm tree in the distance, empty street, $STYLE" 412
gen gedo      "$KITTEN wrapped in a soft knitted wool scarf in a little basket, beside a small round saucer of milk on the floor, a window with a Cairo minaret behind, $STYLE" 413
gen flight    "$LOZA looking out of a soft travel carrier beside a round airplane window full of white clouds, $STYLE" 404
gen home      "$LOZA sitting on a sunny window sill, a blue ocean and tall palm trees outside, San Diego light, $STYLE" 405
gen noah      "$LOZA sitting calmly beside a baby's wooden crib, keeping watch, only a soft blue blanket and a small teddy bear visible through the rails, nobody visible, $STYLE" 416
gen play      "$LOZA batting at a ball of yellow yarn on a soft rug, toy blocks nearby, $STYLE" 407
gen eyes      "close portrait of $LOZA, one eye blue like the sea and one eye green like a leaf, $STYLE" 408
gen days      "$LOZA stretching happily in a warm sunbeam on a rug, $STYLE" 409
gen goodnight "$LOZA asleep curled at the end of a bed, a crescent moon and stars in the window, $STYLE" 410
echo "LOZA IMAGES DONE"
