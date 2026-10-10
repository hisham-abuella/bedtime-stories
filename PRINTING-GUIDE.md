# Printing Guide — from PDF to a real book

How to design a book for print, what options exist, and roughly what each costs.
Written for the books in this repo, but the rules apply to any PDF.

Prices are approximate (researched October 2026) — always confirm in the
vendor's own calculator before ordering.

---

## 1. Design the book: the checklist

Every printer, home or commercial, cares about the same handful of things.
Get these right in the PDF and any option below will work.

| # | Rule | Why |
|---|------|-----|
| 1 | **Pick the trim size first** and make the PDF page exactly that size (plus bleed). | A mismatched size gets scaled, cropped or rejected. |
| 2 | **Add bleed: 3mm (0.125") on every edge** if artwork touches the edge. | Paper is cut with a tolerance; bleed stops white slivers. |
| 3 | **Safe zone: keep text 8–10mm inside the trim.** | Anything near the edge can be cut off. |
| 4 | **Images at 300 DPI** at their printed size (≥ 232 DPI is acceptable for flat illustrations). | Lower looks soft or pixelated. |
| 5 | **Embed all fonts** (Chrome's print-to-PDF does this). | Missing fonts get swapped, and Arabic breaks first. |
| 6 | **Page count:** a multiple of 4 for stapled booklets. Bound books have a minimum, often 24 pages for hardcover. | Folded sheets carry 4 pages; binding needs a spine. |
| 7 | **The cover is a separate file.** For bound books it's one wide spread: back + spine + front. | The spine width depends on page count and paper. The vendor gives you a template. |
| 8 | **Colors:** design in RGB and let the printer convert. Expect prints a bit darker and less saturated than the screen. | Paper isn't backlit. Order one proof copy first. |
| 9 | **Check for clipped text** before printing (see README → "Checking a print edition"). | `overflow:hidden` hides text silently in the PDF. |

### Typical trim sizes for kids' books

| Size | Use |
|------|-----|
| 180mm (7") square | Board books (this repo's `-board` PDFs) |
| 8.5" × 8.5" (216mm) square | The classic picture book. Lulu, Blurb and KDP all offer it. |
| A5 (148 × 210mm) | Home printing and stapled booklets (this repo's `-print` PDFs) |
| 8" × 10" landscape | Wide spreads, photo-book style |

### Building a PDF for a new size from this repo

`tools/make-print.js` already takes `--trim` and `--bleed` in mm. For an 8.5"
square printed book:

```sh
node tools/make-print.js susu.html print/susu-216.html \
  --url https://hisham-abuella.github.io/bedtime-stories/susu.html \
  --qr print/qr-susu.svg --board --art images --trim 216 --bleed 3.2
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
  --no-pdf-header-footer --print-to-pdf=print/susu-216.pdf "file://$PWD/print/susu-216.html"
```

Remove the crop marks if the vendor wants a plain bleed PDF. Lulu and KDP do,
and they reject files with marks.

---

## 2. Your options

### A. At home — stapled booklet (A5)
- **PDF:** `<book>-print.pdf`
- **How:** open it in Adobe Acrobat Reader → Print → Page Sizing → **Booklet**.
  Print double-sided, flipping on the short edge. Fold, crease with a bone folder,
  and staple twice with a long-reach stapler.
- **Cover:** print the cover sheet on 200–250gsm cardstock and laminate it with
  self-adhesive sheets.
- **Quality:** ★★☆ · **Durability:** low (not for a baby who chews)
- **Cost:** ~$1–3 per book in paper and ink. One-time tools: long-reach stapler
  ~$15–25, laminating sheets ~$15.

### B. At home — DIY board book (best for a baby)
- **PDF:** `<book>-board.pdf` or `<book>-board-illustrated.pdf`
- **How:** follow README → "Printing a board book". In short: 300–350gsm card,
  single-sided, trim, laminate, glue back to back, round the corners, bind with
  rings or tape.
- **Quality:** ★★★ · **Durability:** high (survives chewing once laminated)
- **Cost:** ~$5–10 per book. One-time tools: corner punch ~$10, thermal laminator
  ~$30, paper trimmer ~$25.

### C. Local print shop (Staples, FedEx Office, independent)
- **PDF:** either one. Bring it on a USB stick or upload it.
- **Ask for:** "180mm square, single-sided on 350gsm, matte laminate both sides,
  10mm rounded corners, trimmed to crop marks". That gets you a board book.
  You can also ask for an A5 book with a laminated cardstock cover and coil or
  perfect binding.
- **Quality:** ★★★ · **Turnaround:** same day to 2 days
- **Cost:** ~$15–40 per board book (lamination is the expensive part), or
  ~$8–20 for a coil-bound A5 book.

### D. Online board-book printers (thick, real board pages)
- **[Pinhole Press](https://pinholepress.com/custom-story-board-book):** custom
  story board book, ~$42 for 20 pages, +$1 per extra page. Rigid pages. Mostly
  template-based, so check whether it accepts full-page images.
- **[Presto Photo](https://www.prestophoto.com/help/A4+Custom+Childrens+Book):**
  board books and children's books from ~$11.
- **Etsy "PDF to book" sellers:** from ~$6. Quality varies, so read the reviews.
- **Quality:** ★★★★ · **Turnaround:** 1–2 weeks
- **Best for:** a gift-quality board book without any DIY.

### E. Print-on-demand (a real paperback or hardcover)
- **[Lulu](https://www.lulu.com/create/childrens-books):** 8.5" square, premium
  color, paperback or hardcover casewrap, matte or gloss cover.
  - Paperback: ~$8–15 per copy.
  - Hardcover: ~$16–25 per copy.
  - Plus shipping (~$5–10).
- **Also:** Blurb (strong photo-book quality), Amazon KDP (only if you publish
  publicly).
- **Upload:** the interior PDF (all pages, with bleed, no crop marks) and the
  cover PDF built from their template.
- **Watch out:** hardcover usually needs **≥ 24 pages**. A 10-page story needs
  blank, notes or "about this book" pages to reach that. You could also combine
  the four Muslim books into one 40+ page volume.
- **Quality:** ★★★★★ (looks like a bookstore book) · **Turnaround:** ~5–10
  business days
- **Not for babies:** these have paper pages. Use B, C or D for under-twos.

---

## 3. Which one to pick

| Situation | Pick |
|-----------|------|
| Yusuf is going to hold, drop and chew it | **B** (DIY board) or **D** (Pinhole Press) |
| Want it today, decent quality | **C** (local print shop) |
| Quick paper copy to read aloud | **A** (home booklet) |
| Keepsake, gift, or a bundle of all the stories | **E** (Lulu hardcover, all books in one volume) |

**Always order or print one proof copy first.** Check the colors, the Arabic
text, and that the QR code scans from paper.

---

## 4. Approximate cost summary

| Option | Per copy | One-time setup | Turnaround |
|--------|----------|----------------|------------|
| A. Home booklet | $1–3 | $30–40 tools | 30 min |
| B. DIY board book | $5–10 | $60–70 tools | 1–2 hours |
| C. Print shop board book | $15–40 | — | 0–2 days |
| D. Online board book | $6–45 | — | 1–2 weeks |
| E. Lulu paperback / hardcover | $8–15 / $16–25 + shipping | — | 5–10 days |

Sources: [Lulu children's books](https://www.lulu.com/create/childrens-books),
[Pinhole Press](https://pinholepress.com/custom-story-board-book),
[Presto Photo](https://www.prestophoto.com/help/A4+Custom+Childrens+Book),
[Printivity — saddle stitch](https://printivity.com/booklets/saddle-stitched-booklets).
