#!/usr/bin/env python3
"""Where the books live online: the one place the printed QR codes and the
"listen" panels get their addresses from.

Yusuf's two bound volumes -- First Words and Animals and Colours -- and the
shelf have moved to nostalgia-masry.com: every code in both volumes opens the
new site. Every other book (Loza, Noah's copies, Yaseen...) keeps its old GitHub Pages address, which copies are already
printed with.

  python3 tools/siteurls.py shelf            # the shelf the volume covers open
  python3 tools/siteurls.py shelf legacy     # the old shelf (Noah's volumes)
  python3 tools/siteurls.py book <slug>      # the page a book's code opens
  python3 tools/siteurls.py book <slug> legacy   # its GitHub Pages copy
  python3 tools/siteurls.py base <slug>      # that book's site, for --url

To move a book, add or remove its slug in NEW_SITE_BOOKS. To move the domain,
change NEW below. Then: tools/make-qr.py, rebuild, tools/check-qr.py.
"""
import sys

NEW = {   # the books' new home, on the game site
    'shelf': 'https://nostalgia-masry.com/babystories/',
    'book':  'https://nostalgia-masry.com/babystories/{slug}.html',
}
LEGACY = {   # GitHub Pages: books are one level down, in books/
    'shelf': 'https://hisham-abuella.github.io/bedtime-stories/',
    'book':  'https://hisham-abuella.github.io/bedtime-stories/books/{slug}.html',
}
# The books on the new site. Their codes, their board editions and the
# volume covers all point at NEW.
NEW_SITE_BOOKS = {
    'bismillah', 'alhamdulillah', 'khalaqa', 'nabina',   # First Words
    'black-white-zoo', 'susu',                           # Animals and Colours
    'abc', 'huroof',                                     # the alphabet books
}


def site_of(slug):
    return NEW if slug in NEW_SITE_BOOKS else LEGACY


def book_url(slug, which=''):
    site = LEGACY if which == 'legacy' else site_of(slug)
    return site['book'].format(slug=slug)


def shelf_url(which='new'):
    return (LEGACY if which == 'legacy' else NEW)['shelf']


if __name__ == '__main__':
    cmd, arg = (sys.argv[1:] + ['', ''])[:2]
    if cmd == 'shelf':
        print(shelf_url(arg or 'new'))
    elif cmd == 'book' and arg:
        print(book_url(arg, (sys.argv[3:] + [''])[0]))
    elif cmd == 'base' and arg:
        print(site_of(arg)['shelf'])
    else:
        sys.exit('usage: siteurls.py shelf [legacy] | book <slug> [legacy] | base <slug>')
