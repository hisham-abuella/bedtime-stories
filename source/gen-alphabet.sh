#!/bin/zsh
# Pictures for the two alphabet books, My ABC (English) and حروفي (Egyptian),
# drawn locally by Z-Image Turbo at 1536px.
#
#   DEST=$PWD/art-hi/images-alphabet zsh source/gen-alphabet.sh
#
# One picture per word, named by the thing in English, so the two books share
# every picture they have in common (apple is A and ت, the duck is D and ب).
# Each is one object alone on a plain warm background: a toddler points at it,
# so nothing else on the page may compete. Same soft gouache as the First Words
# books, so the alphabets sit beside them on the shelf.
# $STYLE is written on every line, not added inside gen(): tools/try-seeds.sh
# swaps gen() for its own, and without the style the trials came out as photos.
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=${DEST:-$REPO/art-hi/images-alphabet}
SIZE=${SIZE:-1536}
mkdir -p "$DEST"
CLI=$HOME/.local/bin/draw-things-cli
STYLE="warm children's picture book illustration, soft gouache, gentle rounded shapes, one single object centred alone, plain soft warm cream background, generous empty space around it, muted warm palette, simple and clear for a toddler"
NEG="text, letters, words, numbers, arabic script, calligraphy, writing, signs, logo, label, watermark, signature, people, person, human, child, adult, hands, faces on objects, photorealistic, photograph, 3d render, cluttered, busy background, many objects, pattern, deformed, extra limbs, blurry, pig, alcohol, wine, bottle, cross, church, revealing clothing"

gen () {  # name, prompt, seed
  [[ -f "$DEST/$1.png" ]] && { echo "skip $1"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$2" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$3" \
    --output "$DEST/$1.png" >/dev/null 2>&1 && echo "done $1" || echo "FAIL $1"
}

# ---- Shared by both books ----------------------------------------------------
gen apple           "a shiny round red apple with one green leaf on its stem, $STYLE" 1001
gen elephant        "a friendly little grey baby elephant standing, full body, side view, $STYLE" 1002
gen lion            "a friendly little lion cub with a soft golden mane, sitting, full body, $STYLE" 1003
gen rabbit          "a fluffy white rabbit with long ears, sitting, full body, $STYLE" 1004
gen duck            "a little yellow duckling standing, full body, side view, $STYLE" 1005
gen dates           "a small pile of shiny brown dates on a little plate, $STYLE" 1006
gen cat             "a little grey tabby kitten sitting, full body, $STYLE" 1007
gen fish            "a bright orange fish swimming, side view, $STYLE" 1008
gen grapes          "a bunch of purple grapes with a green leaf, $STYLE" 1009
gen giraffe         "a friendly little giraffe standing, full body, $STYLE" 1010
gen horse           "a gentle brown horse standing, full body, side view, $STYLE" 1011
gen lemon           "a bright yellow lemon with a green leaf, $STYLE" 1012
gen moon            "a glowing yellow crescent moon in a small patch of dark blue night sky, $STYLE" 1013
gen milk            "a glass of white milk, $STYLE" 1014
gen star            "one big glowing yellow five-pointed star, $STYLE" 1015
gen sun             "a big round warm yellow sun with soft rays, $STYLE" 1016
gen tree            "a round leafy green tree with a brown trunk, $STYLE" 1017
gen fox             "a friendly little orange fox sitting, full body, fluffy tail, $STYLE" 1018
gen banana          "one ripe curved yellow banana, $STYLE" 1019
gen ball            "a round colourful striped play ball, $STYLE" 1020
gen flower          "one pink flower with a green stem and two leaves, $STYLE" 1021
# Redrawn twice: a ball on a string, then a spool of thread. Front view now.
gen yoyo            "a classic round red toy yo-yo seen from the front as a flat round disc with a small white circle in the middle, hanging from a thin white string that goes straight up out of the picture, $STYLE" 1422
gen mandarin        "one small round orange mandarin with a green leaf, $STYLE" 1023

# ---- English only ------------------------------------------------------------
# six legs asked for: the first try had four.
gen ant             "a small friendly black ant with exactly six thin legs, full body, side view, $STYLE" 1131
gen car             "a small round red toy car, side view, $STYLE" 1102
gen egg             "one white egg in a little egg cup, $STYLE" 1103
gen hat             "a straw sun hat with a ribbon, $STYLE" 1104
gen ice-cream       "an ice cream cone with one pink scoop, $STYLE" 1105
gen igloo           "a small white igloo made of snow blocks on snow, $STYLE" 1106
gen juice           "a glass of orange juice, $STYLE" 1107
gen jellyfish       "a pink jellyfish floating, with wavy tentacles, $STYLE" 1108
gen kite            "a diamond kite with a long tail of bows flying in a small patch of blue sky, $STYLE" 1109
gen key             "an old golden key, $STYLE" 1110
gen nest            "a bird's nest made of twigs with three small blue eggs in it, $STYLE" 1111
gen nuts            "a small pile of brown walnuts and almonds, $STYLE" 1112
gen orange          "a round orange fruit with a green leaf, $STYLE" 1113
gen owl             "a little brown owl with big round eyes sitting on a branch, $STYLE" 1114
gen penguin         "a little penguin standing, full body, $STYLE" 1115
gen pear            "a ripe green pear with a leaf, $STYLE" 1116
gen quilt           "a folded patchwork quilt in soft colours, $STYLE" 1117
gen quail           "a small brown speckled quail bird standing, full body, side view, $STYLE" 1118
gen rainbow         "a soft rainbow arching between two small white clouds, $STYLE" 1119
gen turtle          "a little green turtle walking, full body, side view, $STYLE" 1120
gen umbrella        "an open red umbrella, $STYLE" 1121
gen unicorn         "a little white unicorn with a golden horn and a pastel mane, full body, $STYLE" 1122
gen van             "a small round blue toy van, side view, $STYLE" 1123
gen vase            "a round blue vase with three flowers in it, $STYLE" 1124
gen watermelon      "a slice of red watermelon with black seeds and a green rind, $STYLE" 1125
gen whale           "a friendly blue whale swimming, side view, $STYLE" 1126
gen box             "a closed brown cardboard box tied with string, $STYLE" 1127
gen yogurt          "a small bowl of white yogurt with a spoon, $STYLE" 1128
gen zebra           "a little zebra standing, full body, side view, $STYLE" 1129
# Redrawn: the first was a shapeless blue blob.
gen zipper          "a big shiny metal zipper with a round pull tab, half unzipped, on a small flat piece of yellow fabric, close up, $STYLE" 1331

# ---- Egyptian only -----------------------------------------------------------
gen crocodile       "a friendly little green crocodile, full body, side view, $STYLE" 1201
gen camel           "a friendly camel with one hump standing, full body, side view, $STYLE" 1203
gen carrot          "one orange carrot with green leaves, $STYLE" 1204
gen pigeon          "a soft grey pigeon standing, full body, side view, $STYLE" 1205
gen sheep           "a fluffy white sheep standing, full body, side view, $STYLE" 1206
gen cucumber        "one green cucumber, $STYLE" 1207
gen rooster         "a proud rooster with a red comb standing, full body, side view, $STYLE" 1208
gen teddy           "a soft brown teddy bear sitting, $STYLE" 1209
gen corn            "one yellow corn cob with green husk leaves, $STYLE" 1210
gen gold            "a small pile of shiny round gold coins, $STYLE" 1211
gen pomegranate     "a round red pomegranate with one half open showing red seeds, $STYLE" 1212
gen feather         "one soft white feather, $STYLE" 1213
gen olives          "a small bowl of green olives, $STYLE" 1214
gen clock           "a round wall clock with a plain face and two hands, no numbers, $STYLE" 1215
gen rocket          "a small red and white toy rocket, $STYLE" 1216
gen soap            "a bar of pink soap with a few bubbles, $STYLE" 1217
gen frog            "a little green frog sitting, full body, $STYLE" 1218
gen airplane        "a small white and blue toy airplane flying, side view, $STYLE" 1219
gen tomato          "one round red tomato with a green stem, $STYLE" 1220
gen envelope        "a closed paper envelope with a red heart seal, $STYLE" 1221
gen sparrow         "a little brown sparrow standing, full body, side view, $STYLE" 1222
gen gazelle         "a graceful little gazelle standing, full body, side view, $STYLE" 1223
# Redrawn twice: real machines come with written panels. A toy one has none.
gen washing-machine "a cute chunky toy washing machine, rounded cartoon shape, plain white front with only one big round glass door and one big round knob on top, nothing else on it, no panel, no screen, no labels, $STYLE" 1336
gen strawberry      "a red strawberry with green leaves, $STYLE" 1225
gen cake            "a small round birthday cake with white icing and a cherry, $STYLE" 1226
gen boat            "a small wooden sailing boat on a little wave, $STYLE" 1227
gen bee             "a friendly round bee with yellow and black stripes flying, $STYLE" 1228
gen hoopoe          "a hoopoe bird with its orange crest fanned open, standing, full body, side view, $STYLE" 1229
gen gift            "a wrapped present box with a big ribbon bow, $STYLE" 1230
gen goose           "a white goose standing, full body, side view, $STYLE" 1231
gen fridge          "a small cute rounded cream-coloured fridge with two doors and silver handles, standing alone, $STYLE" 1233
# Redrawn: the first drew the back of a head. Only the braid now, like a ribbon.
gen braid           "a single thick brown plaited braid of hair lying flat on its own like a rope, tied at the bottom with a pink ribbon bow, no head, no face, no person, $STYLE" 1334
# Redrawn: the first shadow was too faint to read.
gen shadow          "a little round green tree standing on grass in bright sunshine, with a long dark grey shadow stretching across the ground beside it, $STYLE" 1336
gen dove            "a soft pale grey turtle dove standing, full body, side view, $STYLE" 1232

echo "ALPHABET IMAGES DONE"
