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
LOZA="a round-faced white cartoon cat with a fluffy white coat, odd eyes — her right eye pale blue and her left eye green — a small dark grey smudge on the very top of her head between the ears, pink inner ears and a small pink nose"
KITTEN="the same cat as a small young kitten: $LOZA"
# asleep: the eye colours are left out, or the model paints one open
SLEEPING="a round-faced white cartoon cat with a fluffy white coat, a small dark grey smudge on the very top of her head between the ears, pink inner ears and a small pink nose, fast asleep with both eyes shut as two curved lines"
STYLE="warm children's picture book illustration, soft gouache, gentle rounded shapes, cosy, generous negative space, muted warm palette"
NEG="text, letters, words, numbers, arabic script, writing, signs, watermark, signature, people, human faces, human hands, photorealistic, cluttered, deformed, extra limbs, extra tails, blurry, tabby stripes, black cat, photograph, photo, 3d render, realistic fur"

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
gen cover     "$LOZA sitting upright facing the viewer, peeking out from a soft round grey cat cave bed, $STYLE" 411

# Mama and Gedo took her from a shelter in San Diego, and she hid for weeks;
# Mama would not give her back. Mama is shown by what she left out for her — a bowl and a toy.
gen shelter   "$KITTEN sitting shyly in a cosy blanket-lined basket inside a bright clean animal shelter room, empty soft kennels in the background, $STYLE" 422
gen hiding    "$KITTEN peeking out shyly from under a bed, only her face and two front paws showing from the shadow beneath a hanging blue bedspread, $STYLE" 426
gen mama      "$KITTEN curled up shyly in a soft cardboard box lined with a blanket, a full food bowl and a small knitted toy mouse placed gently beside the box, warm living room, $STYLE" 428
gen home      "$LOZA sitting on a sunny window sill, a blue ocean and tall palm trees outside, San Diego light, $STYLE" 405
# Mama married Baba: he is his shoes by the door, beside the wedding flowers.
# Feet and legs are in the negative so no person grows out of the shoes.
NEG="$NEG, legs, feet" gen baba "$LOZA curiously sniffing a pair of big brown men's leather shoes on the floor by a front door, a bouquet of white wedding flowers lying beside them, cosy hallway, $STYLE" 436
gen noah      "$LOZA sitting calmly beside a baby's wooden crib, keeping watch, only a soft blue blanket and a small teddy bear visible through the rails, nobody visible, $STYLE" 416
gen play      "$LOZA batting at a ball of yellow yarn on a soft rug, toy blocks nearby, $STYLE" 407
# Pet her a second too long and she bites. Asked for a raised paw, the model
# gave a cross face instead — which says it better for a baby anyway.
gen pet       "$LOZA sitting on a sofa cushion looking cross and grumpy in a funny cartoon way, ears flat back, eyes narrowed, tail puffed up, one front paw raised to swat, $STYLE" 431
gen eyes      "close portrait of $LOZA, one eye blue like the sea and one eye green like a leaf, $STYLE" 408
gen goodnight "$SLEEPING, curled at the end of a bed, a crescent moon and stars in the window, $STYLE" 420
# The back of Noah's Animals and Colours volume: Loza on a rug at night with
# the zoo as soft toys. Awake, so her odd eyes show as on every other page.
gen vol-back  "$LOZA lying contentedly on a soft round rug, awake and looking at the viewer with both eyes open, three small plush toys sitting beside her — a black and white striped zebra, a black and white panda and a black and white penguin — a crescent moon and stars in a window behind, $STYLE" 480
# Noah's First Words: the three pages that show Yusuf's Susu show Loza instead
# (tools/build-noah-first-words.py). The First Words style is the same as hers.
gen fw-bowl   "$LOZA eating happily from a full food bowl on a kitchen floor, a bowl of water beside it, $STYLE" 450
gen fw-bed    "$LOZA sitting calmly at the foot of a child's bed on a soft blanket, keeping an eye on the room, $STYLE" 460
gen fw-night  "$LOZA sitting quietly in soft evening light, her eyes wide and round, a few stars in a deep blue window behind her, $STYLE" 470
echo "LOZA IMAGES DONE"
