#!/usr/bin/env python3
"""Narrate a transcript with Promoat TTS, one mp3 per slide.

    PROMOAT_KEY=pmat_... python3 tools/promoat-tts.py source/<book>-eg.json audio-<book>/eg \
        [--voice sv_...] [--force] [--per-page]

Used for the Egyptian Arabic (مصري) narration.

By default the whole book goes to the voice in ONE request and the result is
cut back into pages at the pauses between them. That matters for the dialect:
Promoat has no accent setting, and a single short page ("السما. واسعة وزرقا…")
gives the model too little to go on, so it falls back to a فصحى delivery. A
whole book of colloquial text in one go is what made the approved Egyptian
Susu sample. --per-page sends one request per slide instead.

The transcripts keep the same v4 audio tags as the ElevenLabs ones, but Promoat
reads them as words, so they are stripped: delivery comes from the punctuation.

Default voice is the studio voice Sarah, the same voice as the فصحى narration.
Price: max(10, ceil(chars / 1000) * 10) credits per request.
"""
import argparse, json, os, pathlib, re, shutil, subprocess, sys, tempfile, urllib.request, urllib.error

BASE = 'https://platform.promoat.ai/api/partner/v1'
KEY = os.environ.get('PROMOAT_KEY') or sys.exit('PROMOAT_KEY not set (add it to ~/.zshrc)')


def call(method, path, body=None):
    req = urllib.request.Request(
        BASE + path, method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': f'Bearer {KEY}', 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f'{method} {path} -> {e.code}: {e.read().decode()}')


def speakable(transcript):
    s = re.sub(r'\[[a-z ]+\]\s*', '', transcript)      # [warmly] and friends
    s = re.sub(r'\s*<break[^>]*/>\s*', ' ', s)         # pauses come from the full stops
    return re.sub(r'\s{2,}', ' ', s).strip()


def speak(text, voice, dest):
    r = call('POST', '/tts', {'voice_id': voice, 'text': text, 'language': 'ar'})
    # the CDN refuses Python's default user agent
    subprocess.run(['curl', '-sSfL', '-A', 'Mozilla/5.0', '-o', str(dest), r['audio_url']], check=True)
    return r.get('credits_charged') or 0


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                          '-of', 'csv=p=0', str(path)], capture_output=True, text=True, check=True)
    return float(out.stdout)


def silences(path):
    """(start, end) of every pause of 0.25 s or more."""
    log = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(path), '-af',
                          'silencedetect=noise=-38dB:d=0.25', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', log)]
    ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', log)]
    return list(zip(starts, ends))


def split_pages(whole, weights):
    """Cut points between pages, or None if the pauses do not line up.

    Page breaks are no longer than sentence breaks in a whole-book take, so a
    pause alone cannot mark one. Instead each break is predicted from the page
    weights (the length of an earlier per-page take of the same page by the
    same voice, or failing that its character count), re-scaled after every
    cut to the time actually left, and snapped to the nearest real pause."""
    total = duration(whole)
    mids = [(s + e) / 2 for s, e in silences(whole)]
    cuts, at = [], 0.0
    for k in range(len(weights) - 1):
        guess = at + (total - at) * weights[k] / sum(weights[k:])
        near = [m for m in mids if m > at + 1.0]
        if not near:
            return None
        best = min(near, key=lambda m: abs(m - guess))
        if abs(best - guess) > 2.0:
            return None
        cuts.append(best)
        at = best
    return cuts


def cut(whole, a, b, dest):
    args = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(whole), '-ss', f'{a:.3f}']
    if b is not None:
        args += ['-to', f'{b:.3f}']
    # trim the pause at both ends so every page starts on its first word
    args += ['-af', 'silenceremove=start_periods=1:start_threshold=-45dB,'
             'areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse,'
             'apad=pad_dur=0.25', '-c:a', 'libmp3lame', '-q:a', '3', str(dest)]
    subprocess.run(args, check=True)


ap = argparse.ArgumentParser()
ap.add_argument('transcript')
ap.add_argument('out_dir')
ap.add_argument('--voice', help='voice_id; default: your Sarah studio voice')
ap.add_argument('--force', action='store_true')
ap.add_argument('--per-page', action='store_true', help='one request per slide (no whole-book context)')
ap.add_argument('--guide', help='folder of earlier per-page takes; their lengths place the page breaks')
ap.add_argument('--resplit', action='store_true', help='re-cut the saved _whole.mp3 instead of a new take (free)')
a = ap.parse_args()

voice = a.voice
if not voice:
    mine = call('GET', '/voices').get('voices', [])
    voice = next((v['voice_id'] for v in mine if v['voice_id'].startswith('sv_sarah_')), None) \
        or call('POST', '/voices', {'name': 'Sarah (Arabic)', 'language': 'arabic', 'studio_voice': 'Sarah'})['voice_id']

out = pathlib.Path(a.out_dir)
out.mkdir(parents=True, exist_ok=True)
slides = json.load(open(a.transcript))['slides']
dests = [out / f"{s['id']}.mp3" for s in slides]
texts = [speakable(s['transcript']) for s in slides]

if a.per_page:
    spent = 0
    for dest, text in zip(dests, texts):
        if dest.exists() and not a.force:
            print(f'  {dest}  (exists)')
            continue
        spent += speak(text, voice, dest)
        print(f'  {dest}  {duration(dest):.1f}s')
    sys.exit(print(f'{len(slides)} slides, {spent} credits'))

if all(d.exists() for d in dests) and not a.force:
    sys.exit(print(f'{out}: all {len(dests)} pages exist (use --force to remake)'))

keep = out / '_whole.mp3'                    # kept beside the pages, so a bad split can be redone for free
if a.resplit:
    whole, spent = keep, 0
else:
    whole = pathlib.Path(tempfile.mkdtemp()) / 'whole.mp3'
    spent = speak('\n\n'.join(texts), voice, whole)
    shutil.copy(whole, keep)
guide = [pathlib.Path(a.guide) / d.name for d in dests] if a.guide else []
weights = [duration(g) for g in guide] if guide and all(g.exists() for g in guide) else [len(t) for t in texts]
cuts = split_pages(whole, weights)
if not cuts:
    sys.exit(f'could not find {len(texts) - 1} page breaks in {keep}; nothing replaced ({spent} credits)')
bounds = [0.0] + cuts + [None]
for i, dest in enumerate(dests):
    cut(whole, bounds[i], bounds[i + 1], dest)
    was = f'  (was {weights[i]:.1f}s)' if guide else ''
    print(f'  {dest}  {duration(dest):.1f}s{was}  {texts[i][:40]}')
print(f'{len(slides)} pages from one {duration(whole):.0f}s take, {spent} credits')
