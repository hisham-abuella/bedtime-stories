#!/bin/zsh
# Artwork for Yaseen's Big Year, drawn locally by Z-Image Turbo.
# The boy is on every page, so everything about him is pinned in words and
# reused verbatim: face feature by feature, the hair exactly, three outfits.
# Left looser, the model drifts to a thick-browed boy who is somebody else, or
# gives him brown hair. No grown-up is drawn at all: arms and laps came out
# mangled, so Mama, Baba and Coach live in the words. The baby is always
# described as much smaller than him. A small red toy trolley hides on every
# page, the way the red bird hides in the zoo.
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=${DEST:-$REPO/images-yaseen}
SIZE=${SIZE:-1024}
mkdir -p "$DEST"
CLI=/opt/homebrew/bin/draw-things-cli
HAIR="jet-black hair, short and messy, with a soft fringe over his forehead and one little tuft sticking up on top"
BOY="a cheerful four-year-old cartoon boy with $HAIR, fair skin, round soft face, small thin eyebrows, round rosy cheeks"
YASEEN="$BOY, big dark brown eyes and a bright smile"
# asleep: the eyes are left out of the description, or the model paints them open
ASLEEP="$BOY, fast asleep with both eyes shut as two curved lines, peaceful smile"
TEE="wearing a red t-shirt and blue jeans"
KIT="wearing a blue soccer jersey, white shorts, blue and white striped socks and black soccer boots"
PJS="wearing light blue pyjamas"
BABY="a very tiny newborn baby girl, no bigger than a loaf of bread and less than half the size of the boy, swaddled in a soft pink blanket, eyes closed"
TROLLEY="a tiny red toy trolley tram hidden somewhere in the corner of the scene"
STYLE="bright cartoon children's book illustration, bold clean black outlines, flat vibrant colours, simple rounded shapes, big expressive eyes, playful and cheerful, sunny San Diego palette of sky blue, ocean teal, palm green and warm sand, plain uncluttered background"
NEG="bob haircut, bowl cut, hair covering ears, brown hair, dark brown hair, long hair, spiky hair, thick eyebrows, bushy eyebrows, crayon shin-chan, girl, adult, grown-up, man, woman, adult arms, adult hands, extra arms, extra hands, photorealistic, photograph, 3d render, realistic skin, painterly, gouache, watercolour texture, text, letters, words, numbers, arabic script, writing, signs, logo, label, watermark, crowd, extra fingers, deformed hands, extra limbs, cluttered, dark, scary, blurry, cross, church, pig, alcohol, revealing clothing, bare shoulders"

gen () {
  [[ -f "$DEST/$1.png" ]] && { echo "skip $1"; return; }
  $CLI generate --model z_image_turbo_1.0_q8p.ckpt \
    --prompt "$2, $STYLE" --negative-prompt "$NEG" \
    --width $SIZE --height $SIZE --seed "$3" \
    --output "$DEST/$1.png" >/dev/null 2>&1 && echo "done $1" || echo "FAIL $1"
}

gen cover      "$YASEEN $KIT, holding a soccer ball under one arm and waving, a bright red trolley tram passing behind him, palm trees and blue sky" 600

# 1 · Hello, Yaseen
gen hello      "$YASEEN $TEE, waving at the viewer from his sunny bedroom, palm trees and blue sky through the window, $TROLLEY" 601
gen love       "$YASEEN $TEE, sitting on a cosy sofa happily hugging a big soft heart-shaped cushion, little red hearts floating around him, $TROLLEY" 802
gen favourites "$YASEEN $TEE, sitting on a rug surrounded by his favourite things: a soccer ball, a wooden toy train track with a red toy trolley, a stack of picture books" 603
gen morning    "$YASEEN $PJS, sitting at a kitchen table eating a bowl of cereal, a glass of orange juice, morning sunshine through the window, $TROLLEY" 604
gen dressed    "$YASEEN in his bedroom pulling a red t-shirt down over his head by himself, one arm through a sleeve, blue jeans, proud face, one sock on the floor, $TROLLEY" 705

# 2 · Yaseen Starts Preschool
gen backpack   "$BOY, big dark brown eyes, a little worried face, $PJS, sitting on his bed in the evening hugging a new small blue backpack, warm lamp light, $TROLLEY" 606
gen trolley    "$YASEEN $TEE with a small blue backpack, on a sunny sidewalk pointing excitedly at a bright red trolley tram rolling past, palm trees" 607
gen door       "$BOY, big dark brown eyes, a shy nervous face, $TEE with a small blue backpack, standing alone at the colourful doorway of a preschool, $TROLLEY" 808
gen brave      "$YASEEN $TEE with a small blue backpack, taking a big brave breath with his chest puffed out, then waving goodbye at the doorway of a colourful preschool, $TROLLEY" 609
gen circle     "$YASEEN $TEE, sitting cross-legged on a colourful carpet in a circle with other preschool children, all singing with mouths open, bright classroom, $TROLLEY" 610
gen paint      "$YASEEN $TEE, painting a picture of a train at an easel in a bright preschool classroom, paint on his fingers, wooden blocks nearby, $TROLLEY" 611
gen playground "$YASEEN $TEE, leading a line of laughing preschool children holding each other's shoulders like a train on a sunny playground, $TROLLEY" 612
gen friend     "$YASEEN $TEE, sitting on a classroom floor building a train out of wooden blocks with another little boy who is shy but starting to smile, $TROLLEY" 613

# 3 · Soccer Star
gen training   "$YASEEN $KIT, standing proudly on a green soccer field with a ball at his feet, little orange cones behind him, palm trees, $TROLLEY" 614
gen warmup     "$YASEEN $KIT, doing jumping jacks with his little teammates on a green soccer field, palm trees, $TROLLEY" 615
gen dribble    "$YASEEN $KIT, dribbling a soccer ball through a zigzag line of small orange cones on a green field, motion lines, $TROLLEY" 616
gen listen     "$YASEEN $KIT, sitting on the grass with his little teammates listening carefully, a whistle on a cord and a soccer ball on the grass in front of them, $TROLLEY" 917
gen goal       "$YASEEN $KIT, celebrating with both arms up as the soccer ball hits the net of a small goal, little teammates cheering behind him, $TROLLEY" 618
gen handshake  "$YASEEN $KIT, shaking hands with a smiling little boy with curly brown hair in a yellow soccer jersey from the other team, a small grass stain on his knee, $TROLLEY" 919
gen backyard   "$YASEEN $TEE, kicking a soccer ball into a small empty goal in a sunny backyard at golden hour, $TROLLEY" 820

# 4 · The Trip to Del Mar
gen saturday   "$YASEEN, very short cropped boy's hair with ears showing, $TEE, packing a plain blank lunch box into a small backpack by the front door, excited, $TROLLEY" 9213
gen drive      "$YASEEN $TEE, buckled into a child car seat, looking out of the car window at the blue ocean and the coast, $TROLLEY" 622
gen cliffs     "$YASEEN, very short cropped boy's hair with ears showing, $TEE, standing on a grassy clifftop path behind a wooden fence, the ocean below and railway tracks running along the coast far below, $TROLLEY" 9233
gen wait       "$YASEEN $TEE, wearing a sun hat, on a grassy clifftop with one hand cupped to his ear listening, seagulls flying, ocean waves below, $TROLLEY" 724
gen beep       "$YASEEN $TEE, wearing a sun hat, behind a wooden fence on a clifftop waving both hands at a long blue and white passenger train passing along the coast below, ocean waves, $TROLLEY" 625
gen count      "$YASEEN $TEE, wearing a sun hat, pointing and counting the cars of a long passenger train running along the coast below the cliffs, behind a wooden fence, $TROLLEY" 626
gen sunset     "$YASEEN $TEE, sitting on a picnic blanket on a grassy clifftop eating a sandwich, watching an orange sunset over the ocean, $TROLLEY" 727

# 5 · A Baby Is Coming
gen news       "$BOY, amazed face with big dark brown eyes and an open-mouthed smile, $TEE, sitting on a sofa with both hands on his cheeks, a little thought bubble above him showing a tiny baby in a pink blanket, $TROLLEY" 828
gen stilllove  "$BOY, eyes closed and smiling contentedly, $TEE, curled up cosy under a soft blanket on a sofa, big red hearts floating around him, $TROLLEY" 929
gen small      "$YASEEN $TEE, sitting on the floor holding a soccer ball and looking in surprise at a tiny pair of baby socks next to it, $TROLLEY" 630
gen kick       "$YASEEN $TEE, laughing in delighted surprise with one hand on his cheek, a little thought bubble above him showing a tiny baby foot kicking a tiny soccer ball, $TROLLEY" 831
gen hands      "$YASEEN $TEE, looking down at his own two open hands, a soft white feather floating just above them, $TROLLEY" 632
gen teddy      "$YASEEN $TEE, sitting on a rug carefully cradling a teddy bear wrapped in a small blanket like a baby, one hand gently supporting its head, $TROLLEY" 733
gen room       "$YASEEN $TEE, folding tiny baby clothes beside a white crib in a pastel pink nursery, $TROLLEY" 634
gen toy        "$YASEEN $TEE, proudly placing a soft blue plush toy train into a white crib in a pastel pink nursery, $TROLLEY" 635

# 6 · Big Brother Yaseen
gen time       "$YASEEN $PJS, standing excitedly by the front door in the early morning, a small packed bag ready beside him, $TROLLEY" 636
gen drawing    "$YASEEN $TEE, sitting at a table drawing with crayons, his picture shows a train and a baby, $TROLLEY" 637
gen here       "full body view of $YASEEN $TEE, standing beside a small white bassinet and leaning in to look; inside lies $BABY, her tiny hand wrapped around one of his fingers, $TROLLEY" 838
gen holding    "$YASEEN $TEE, sitting on a sofa propped up by big cushions, very carefully holding $BABY in his arms, her head resting in the crook of his elbow, $TROLLEY" 839
gen jobs       "$YASEEN $TEE, carrying a clean nappy and a folded soft blanket, $BABY lying in a bassinet nearby, $TROLLEY" 640
gen ourtime    "$YASEEN $PJS, snuggled in bed reading a picture book, a soccer ball beside the bed, warm lamp light, $TROLLEY" 841
gen whisper    "$YASEEN $PJS, standing beside a crib with a finger on his lips singing softly, $BABY sleeping in the crib, little music notes floating, $TROLLEY" 642
gen promise    "$YASEEN $TEE, lying on his tummy on a play mat next to $BABY, showing her a soccer ball and a toy train, $TROLLEY" 643
gen goodnight  "$ASLEEP, very short cropped boy's hair with ears showing, $PJS, lying in his bed with his head on the pillow and a blanket pulled up to his chest, a soccer ball and a small red toy trolley on the shelf, dark blue night sky with a crescent moon and stars over the ocean through the window, dim cosy night-time room" 9445
echo "YASEEN IMAGES DONE"
