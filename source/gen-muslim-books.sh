#!/bin/zsh
# Artwork for the four Muslim baby books, drawn locally by Z-Image Turbo.
#
# Two rules are enforced here rather than left to chance:
#   1. No figure ever stands in for the Prophet, peace be upon him. The pages
#      about him show what he loved — children, a cat, dates, clean water,
#      bread — and never a person meant to be him.
#   2. The negative prompt blocks idols, statues, crosses, churches, pigs,
#      alcohol and immodest dress, so nothing turns up by accident.
# Models also cannot write Arabic; any script they produce is nonsense, so text
# is pushed hard into the negative prompt too.

CLI=/opt/homebrew/bin/draw-things-cli
REPO=$(cd "$(dirname "$0")/.." && pwd)
ART_ROOT=${ART_ROOT:-$REPO}
SIZE=${SIZE:-1024}

WARM="warm children's picture book illustration, soft gouache, gentle rounded shapes, cosy, generous negative space, muted warm palette"
NEG="text, letters, words, numbers, arabic script, calligraphy, writing, watermark, signature, photorealistic, cluttered, busy, deformed, extra limbs, extra fingers, blurry, cross, church, statue, idol, shrine, pig, dog, alcohol, wine, bottle, musical instruments, revealing clothing, bare shoulders, adult face, crowd"

gen () {  # book, name, prompt, seed
  local dest="$ART_ROOT/images-$1"
  mkdir -p "$dest"
  [[ -f "$dest/$2.png" ]] && { echo "skip  $1/$2"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$3, $WARM" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$4" \
    --output "$dest/$2.png" >/dev/null 2>&1 && echo "done  $1/$2" || echo "FAIL  $1/$2"
}

# ---- Bismillah: one ordinary moment of the day ------------------------------
gen bismillah cover     "sunrise over a small quiet house, one warm lit window" 401
gen bismillah waking    "morning sunlight coming through a window onto a child's bed" 402
gen bismillah water     "clear water pouring from a small jug over two small child's hands" 403
gen bismillah eating    "a small bowl of dates and a loaf of warm bread on a wooden table" 404
gen bismillah drinking  "a glass of cool clear water on a wooden table in soft light" 405
gen bismillah door      "an open wooden door with warm morning light outside, small shoes on the step" 406
gen bismillah home      "a small house in the evening with one lit window, warm and welcoming" 407
gen bismillah bowl      "a brown and grey tabby cat eating from a full bowl beside a bowl of water" 408
gen bismillah sleep     "a sleeping baby in a cot under a soft blanket, a dim warm lamp" 409
gen bismillah goodnight "a crescent moon and stars over a quiet sleeping house at night" 410

# ---- Alhamdulillah: eight plain gifts ---------------------------------------
gen alhamdulillah cover      "two small open child's hands held up in soft warm light" 421
gen alhamdulillah hands      "two small baby hands with open fingers, close up, soft plain background" 422
gen alhamdulillah eyes       "a baby's wide round eyes looking up, gentle and calm" 423
gen alhamdulillah voice      "a baby in soft pyjamas lying on a blanket, turning its head towards a warm light, fully clothed" 471
gen alhamdulillah bread      "a warm loaf of bread on a cloth, gentle steam rising" 425
gen alhamdulillah cool-water "a tall glass of cool clear water, cold and fresh" 426
gen alhamdulillah rain       "rain falling on a green garden seen through a window" 427
gen alhamdulillah susu       "a brown and grey mackerel tabby cat with white paws, sitting calmly" 428
gen alhamdulillah bed        "a small cosy bed with a warm blanket in a quiet room" 429
gen alhamdulillah goodnight  "a crescent moon and stars above a quiet bedroom window" 430

# ---- Allah Made It: eight pieces of the world -------------------------------
gen khalaqa cover     "a crescent moon above a calm sea with a date palm on the shore" 441
gen khalaqa sky       "a wide blue sky with soft white clouds" 442
gen khalaqa sea       "gentle waves coming up a sandy shore" 443
gen khalaqa palm      "a tall date palm tree heavy with bunches of dates in warm sunlight" 444
gen khalaqa bee       "a honey bee on a bright open flower" 445
gen khalaqa bird      "a small bird perched on a thin branch" 446
gen khalaqa cat       "a cat with wide round eyes sitting in soft evening light" 447
# no child perched on the moon: the page teaches that the real moon was made
gen khalaqa moon      "a crescent moon and many stars in a deep blue night sky, empty sky, no people" 472
gen khalaqa rain      "heavy rain falling in visible streaks onto fresh green grass, puddles, wet leaves, rainy day" 473
gen khalaqa goodnight "a sleeping baby under a blanket beneath a window full of stars" 450

# ---- The Prophet Loved: what he loved, never him ----------------------------
gen nabina cover     "a mosque with a green dome and two slender minarets at dusk, a crescent moon above" 461
gen nabina children  "two small children playing happily in a sunny courtyard" 462
gen nabina salam     "a small child waving one open hand in greeting, warm light" 463
gen nabina smile     "a small child smiling brightly, soft warm plain background" 464
gen nabina cat       "a tabby cat drinking water from a clay bowl" 465
gen nabina dates     "a plate of fresh dates and a cup of milk on a wooden table" 466
gen nabina clean     "a clay water jug, a bowl of clean water and a small green twig" 467
gen nabina bread     "two small hands sharing a round loaf of bread" 468
gen nabina home      "a tidy simple room with a folded cloak, a small oil lamp and a broom" 469
gen nabina goodnight "a mosque with a green dome at night, a crescent moon and many stars" 470

echo "MUSLIM BOOK IMAGES DONE"
