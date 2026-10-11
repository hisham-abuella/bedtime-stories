/* Loza — a white cat with odd eyes (blue on her right, green on her left) and
   a smudge of dark grey on the top of her head. White on white paper only works
   because the outline carries her, so every edge of her keeps the full stroke. */

var LZ_FUR = '#FFFFFF', LZ_SMUDGE = '#4A4A4C', LZ_BLUE = '#7FA9D6',
    LZ_GREEN = '#A9C46A', LZ_PINK = '#E9A3AE', LZ_WARM = '#E8C27A';

var LOZA_SIT = `
  <path d="M286 318 q66 10 58 -54 q-4 -26 -26 -22 q-18 4 -14 24" fill="none" stroke="${INK}" stroke-width="26" stroke-linecap="round"/>
  <path d="M286 318 q66 10 58 -54 q-4 -26 -26 -22 q-18 4 -14 24" fill="none" stroke="${LZ_FUR}" stroke-width="14" stroke-linecap="round"/>
  <ellipse cx="200" cy="286" rx="84" ry="94" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8"/>
  <path d="M184 300 q-6 40 -18 50 M216 300 q6 40 18 50" fill="none" stroke="${INK}" stroke-width="5" stroke-linecap="round" opacity=".5"/>
  <ellipse cx="166" cy="356" rx="30" ry="20" fill="${LZ_FUR}" stroke="${INK}" stroke-width="7"/>
  <ellipse cx="234" cy="356" rx="30" ry="20" fill="${LZ_FUR}" stroke="${INK}" stroke-width="7"/>
  <path d="M120 112 l8 -82 l70 52 z" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
  <path d="M280 112 l-8 -82 l-70 52 z" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
  <path d="M134 94 l5 -44 l36 28 z" fill="${LZ_PINK}"/>
  <path d="M266 94 l-5 -44 l-36 28 z" fill="${LZ_PINK}"/>
  <circle cx="200" cy="160" r="82" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8"/>
  <path d="M150 104 q16 -20 46 -18 q-4 14 -14 22 q-8 10 -14 24 q-10 -8 -18 -28 z" fill="${LZ_SMUDGE}" opacity=".85"/>
  <g fill="${LZ_SMUDGE}" opacity=".55"><circle cx="204" cy="94" r="5"/><circle cx="212" cy="104" r="4"/><circle cx="196" cy="112" r="3.5"/></g>
  <ellipse cx="170" cy="160" rx="21" ry="22" fill="${LZ_BLUE}" stroke="${INK}" stroke-width="6"/>
  <ellipse cx="230" cy="160" rx="21" ry="22" fill="${LZ_GREEN}" stroke="${INK}" stroke-width="6"/>
  <ellipse cx="170" cy="160" rx="6" ry="16" fill="${INK}"/>
  <ellipse cx="230" cy="160" rx="6" ry="16" fill="${INK}"/>
  <circle cx="175" cy="151" r="5" fill="${LZ_FUR}"/>
  <circle cx="235" cy="151" r="5" fill="${LZ_FUR}"/>
  <path d="M200 186 l13 10 -13 10 -13 -10 z" fill="${LZ_PINK}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <path d="M200 206 v8 M200 214 q-14 16 -26 2 M200 214 q14 16 26 2" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>
  <g stroke="${INK}" stroke-width="4" stroke-linecap="round" fill="none" opacity=".8">
    <path d="M156 192 l-52 -14 M156 204 l-54 8 M244 192 l52 -14 M244 204 l54 8"/>
  </g>`;

var LOZA_CURL = `
  <ellipse cx="200" cy="330" rx="170" ry="34" fill="${INK}" opacity=".12"/>
  <path d="M206 160 q150 0 154 106 q4 82 -112 82 q-64 0 -64 -38 q0 -32 54 -32 q48 0 48 -32 q0 -38 -80 -38 z"
        fill="${LZ_FUR}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
  <path d="M86 190 l-14 -70 l70 40 z" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
  <path d="M200 156 l24 -68 l-76 36 z" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
  <path d="M98 176 l-8 -38 l38 22 z" fill="${LZ_PINK}"/>
  <path d="M190 152 l14 -36 l-40 18 z" fill="${LZ_PINK}"/>
  <circle cx="142" cy="214" r="92" fill="${LZ_FUR}" stroke="${INK}" stroke-width="8"/>
  <path d="M98 150 q16 -22 46 -20 q-4 14 -14 22 q-8 10 -12 22 q-12 -6 -20 -24 z" fill="${LZ_SMUDGE}" opacity=".85"/>
  <path d="M96 208 q22 20 44 0 M142 208 q22 20 44 0" fill="none" stroke="${INK}" stroke-width="8" stroke-linecap="round"/>
  <path d="M142 240 l14 11 -14 11 -14 -11 z" fill="${LZ_PINK}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <path d="M142 264 q-14 16 -26 2 M142 264 q14 16 26 2" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>
  <ellipse cx="226" cy="320" rx="34" ry="22" fill="${LZ_FUR}" stroke="${INK}" stroke-width="7"/>
  <g stroke="${INK}" stroke-width="4" stroke-linecap="round" fill="none" opacity=".8">
    <path d="M96 248 l-54 -12 M96 260 l-52 12 M188 248 l50 -12 M188 260 l48 12"/>
  </g>`;

/* Loza scaled into a corner: tx, ty, scale */
function loza(tx, ty, s) { return '<g transform="translate(' + tx + ',' + ty + ') scale(' + s + ')">' + LOZA_SIT + '</g>'; }

/* a small heart */
function heart(cx, cy, s, fill) {
  s = s || 1;
  return g(path('M0 18 q-34 -20 -34 -42 q0 -20 18 -20 q12 0 16 12 q4 -12 16 -12 q18 0 18 20 q0 22 -34 42 z', fill || LZ_PINK, 6),
    'transform="translate(' + cx + ',' + cy + ') scale(' + s + ')"');
}

ART.cover = svg('Loza, a white cat with one blue eye and one green eye',
  '<circle cx="200" cy="210" r="168" fill="' + SKY + '" opacity=".22"/>' + LOZA_SIT);

ART.cairo = svg('A tiny white kitten alone on a Cairo street, a minaret behind',
  rect(28, 120, 90, 200, 6, LZ_WARM) + rect(282, 150, 90, 170, 6, SAND) +
  rect(52, 150, 40, 44, 4, CREAM) + rect(306, 180, 40, 44, 4, CREAM) +
  rect(186, 60, 28, 140, 4, CREAM) + path('M180 60 q20 -40 40 0 z', GOLD) + crescent(200, 22, 10, CREAM) +
  path('M0 320 h400', null, 8) +
  loza(116, 170, .42));

ART.gedo = svg('The kitten wrapped in a warm scarf with a saucer of milk',
  path('M60 300 q0 -70 140 -70 q140 0 140 70 q0 40 -140 40 q-140 0 -140 -40 z', CLAY) +
  path('M80 290 q60 22 120 0 q60 -22 120 0', null, 6) +
  ell(320, 340, 46, 14, CREAM) + ell(320, 336, 30, 7, '#FFFFFF', 4) +
  heart(330, 80, 1.1) +
  loza(96, 72, .52));

ART.flight = svg('Loza looking out of an airplane window at the clouds',
  rect(196, 40, 170, 230, 80, SKY, 10) +
  path('M226 170 q10 -30 40 -20 q14 -24 40 -10 q30 -6 34 22 q4 26 -24 26 h-74 q-26 0 -16 -18 z', CREAM, 6) +
  path('M248 96 l40 -8 l40 8 l-40 8 z', CREAM, 5) +
  loza(-30, 90, .7));

ART.home = svg('Loza on a sunny window sill with the sea and a palm tree outside',
  rect(140, 30, 240, 230, 10, SKY) +
  path('M140 190 q60 -18 120 0 q60 18 120 0 v70 h-240 z', SEA, 6) +
  sun(320, 86, 26) +
  palmTree(200, 110, .5) +
  rect(120, 258, 280, 24, 8, CREAM) +
  loza(-24, 70, .72));

ART.noah = svg("Loza sitting beside a baby's crib",
  '<g stroke="' + INK + '" stroke-width="8" stroke-linejoin="round">' +
  '<rect x="196" y="150" width="190" height="150" rx="14" fill="' + CREAM + '"/>' +
  '<path d="M226 150 v150 M258 150 v150 M290 150 v150 M322 150 v150 M354 150 v150" fill="none"/>' +
  '<path d="M196 250 h190 v50 a14 14 0 0 1 -14 14 h-162 a14 14 0 0 1 -14 -14 z" fill="' + SKY + '"/>' +
  '<rect x="186" y="132" width="210" height="24" rx="12" fill="' + FUR + '"/>' +
  '<path d="M206 314 v26 M376 314 v26" fill="none" stroke-linecap="round"/></g>' +
  star(120, 70, 22) +
  loza(-74, 56, .74));

ART.play = svg('Loza with a ball of yellow yarn',
  circ(318, 316, 46, SAND) +
  path('M286 296 q30 -14 62 6 M280 322 q36 -16 74 8 M296 346 q24 -8 46 4', null, 5) +
  path('M276 330 q-60 40 -120 20 q-50 -16 -90 20', null, 6) +
  rect(30, 90, 54, 54, 8, LZ_BLUE) + rect(92, 90, 54, 54, 8, LZ_GREEN) + rect(60, 36, 54, 54, 8, LZ_PINK) +
  loza(60, 40, .78));

ART.eyes = svg('Close up of Loza: one blue eye, one green eye',
  '<g transform="translate(-80,-20) scale(1.4)">' + LOZA_SIT + '</g>');

ART.days = svg('A very happy Loza in the sunshine',
  sun(330, 74, 40) +
  heart(96, 110, 1.3) +
  loza(0, 22, .94));

ART.goodnight = svg('Loza asleep at the end of the bed under a moon',
  crescent(320, 76, 56, LZ_WARM) +
  star(70, 64, 18) + star(150, 122, 13) + star(64, 160, 11) +
  '<g stroke="' + INK + '" stroke-width="8" stroke-linejoin="round">' +
  '<path d="M30 262 h340 v70 a16 16 0 0 1 -16 16 h-308 a16 16 0 0 1 -16 -16 z" fill="' + SKY + '"/>' +
  '<path d="M30 262 q0 -40 44 -40 h86 q44 0 44 40 z" fill="' + CREAM + '"/></g>' +
  '<g transform="translate(70,36) scale(.6)">' + LOZA_CURL + '</g>');
