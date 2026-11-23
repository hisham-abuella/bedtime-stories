/* A soft lullaby under every book's narration, on repeat, with a choice of eight.
 *
 * Every page in books/ loads this with <script src="lullaby.js" defer>.
 * It is on by default: the music starts the first time any narration plays
 * (browsers only allow sound after a tap), loops for as long as the book is
 * open, and drops quieter while a voice speaks. The ♪ button opens a list to
 * pick a lullaby or turn the music off; the choice is remembered across books.
 *
 * The tracks are in audio-lullaby/, all instrumental, all loudness-matched
 * (ffmpeg loudnorm, -20 LUFS) so switching never jumps in volume. Credits are
 * in TRACKS below and shown in the list.
 */
(function () {
  'use strict';
  var TRACKS = [
    { id: 'brahms',      name: 'Brahms Lullaby',         by: 'BrunoXe',          lic: 'CC BY 3.0', url: 'https://www.jamendo.com/track/379363' },
    { id: 'brahms-box',  name: 'Brahms, music box',      by: 'Garuda1982',       lic: 'CC0',       url: 'https://freesound.org/s/416384/' },
    { id: 'waltz',       name: 'Lullaby Waltz (piano)',  by: 'FlauschGAU',       lic: 'CC BY 3.0', url: 'https://www.jamendo.com/track/1518616' },
    { id: 'calm',        name: 'Calm Lullaby',           by: 'Nesmeyana',        lic: 'CC BY 3.0', url: 'https://www.jamendo.com/track/234275' },
    { id: 'dreamy',      name: 'Goodnight Lullaby',      by: 'Steven Booth',     lic: 'CC BY 3.0', url: 'https://www.jamendo.com/track/1715278' },
    { id: 'music-box',   name: 'Little Music Box',       by: 'sonically_sound',  lic: 'CC0',       url: 'https://freesound.org/s/613178/' },
    { id: 'celesta',     name: 'Twinkly Celesta',        by: 'GregorQuendel',    lic: 'CC BY 4.0', url: 'https://freesound.org/s/578725/' },
    { id: 'antique-box', name: 'Old Music Box',          by: 'csnmedia',         lic: 'CC0',       url: 'https://freesound.org/s/381973/' }
  ];
  var LOUD = 0.28, UNDER = 0.1;   // between pages, and under a voice

  function get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function set(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  var on = get('lullaby') !== 'off';
  var pick = get('lullaby-track');
  if (!TRACKS.some(function (t) { return t.id === pick; })) pick = TRACKS[0].id;

  var music = new Audio();
  music.loop = true;
  music.preload = 'none';
  music.volume = LOUD;
  function src(id) { return '../audio-lullaby/' + id + '.mp3'; }
  music.src = src(pick);

  var speaking = 0;   // narration clips playing right now
  function fadeTo(v) {
    var step = (v - music.volume) / 10, n = 0;
    clearInterval(fadeTo.t);
    fadeTo.t = setInterval(function () {
      music.volume = Math.min(1, Math.max(0, music.volume + step));
      if (++n >= 10) { music.volume = v; clearInterval(fadeTo.t); }
    }, 40);
  }
  function play() { if (on && music.paused) music.play().catch(function () {}); }

  // Any other <audio> on the page is narration (or a sound effect).
  document.addEventListener('play', function (e) {
    if (e.target === music || e.target.tagName !== 'AUDIO') return;
    speaking++;
    play();
    fadeTo(UNDER);
  }, true);
  function stopped(e) {
    if (e.target === music || e.target.tagName !== 'AUDIO') return;
    speaking = Math.max(0, speaking - 1);
    if (!speaking) fadeTo(LOUD);
  }
  document.addEventListener('pause', stopped, true);
  document.addEventListener('ended', stopped, true);

  // ---- the button and its list ---------------------------------------------
  var css = document.createElement('style');
  css.textContent =
    '.lul{position:fixed;bottom:14px;right:14px;z-index:50;font:15px/1.3 system-ui,sans-serif}' +
    '.lul-btn{width:46px;height:46px;border-radius:50%;border:1px solid rgba(252,251,246,.25);' +
    'background:rgba(28,27,23,.85);color:#F3EEDD;font-size:20px;cursor:pointer;box-shadow:0 4px 14px rgba(0,0,0,.3)}' +
    '.lul-btn[aria-pressed="false"]{opacity:.55;text-decoration:line-through}' +
    '.lul-menu{position:absolute;bottom:56px;right:0;width:min(290px,calc(100vw - 28px));max-height:70vh;overflow:auto;' +
    'background:#FCFBF6;color:#1E1B16;border-radius:16px;padding:8px;box-shadow:0 12px 40px rgba(0,0,0,.4);direction:ltr;text-align:left}' +
    '.lul-menu[hidden]{display:none}' +
    '.lul-menu button{display:block;width:100%;text-align:left;border:none;background:none;border-radius:10px;' +
    'padding:9px 10px;cursor:pointer;font:inherit;color:inherit}' +
    '.lul-menu button:hover,.lul-menu button:focus-visible{background:#EFE9DA}' +
    '.lul-menu button[aria-checked="true"]{background:#F3DCCF;font-weight:700}' +
    '.lul-menu small{display:block;font-size:11px;color:#7D786B;font-weight:400}' +
    '.lul-menu small a{color:inherit}' +
    '@media print{.lul{display:none}}';
  document.head.appendChild(css);

  var box = document.createElement('div');
  box.className = 'lul';
  var btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'lul-btn';
  btn.textContent = '♪';
  btn.setAttribute('aria-label', 'Lullaby music');
  btn.setAttribute('aria-haspopup', 'true');
  var menu = document.createElement('div');
  menu.className = 'lul-menu';
  menu.setAttribute('role', 'menu');
  menu.hidden = true;

  function item(label, sub, id) {
    var b = document.createElement('button');
    b.type = 'button';
    b.setAttribute('role', 'menuitemradio');
    b.dataset.id = id;
    b.textContent = label;
    if (sub) { var s = document.createElement('small'); s.innerHTML = sub; b.appendChild(s); }
    b.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') return;    // the credit link opens, the choice stays
      choose(id);
    });
    menu.appendChild(b);
  }
  item('No music', '', 'off');
  TRACKS.forEach(function (t) {
    item(t.name, 'by <a href="' + t.url + '" target="_blank" rel="noopener">' + t.by + '</a>, ' + t.lic, t.id);
  });

  function show() {
    btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    [].forEach.call(menu.children, function (b) {
      b.setAttribute('aria-checked', String(on ? b.dataset.id === pick : b.dataset.id === 'off'));
    });
  }
  function choose(id) {
    if (id === 'off') {
      on = false; set('lullaby', 'off'); music.pause();
    } else {
      on = true; set('lullaby', 'on');
      if (id !== pick) { pick = id; set('lullaby-track', id); music.src = src(id); }
      music.volume = speaking ? UNDER : LOUD;
      music.play().catch(function () {});     // a tap here is allowed to start sound
    }
    show();
  }
  btn.addEventListener('click', function () { menu.hidden = !menu.hidden; });
  document.addEventListener('click', function (e) { if (!box.contains(e.target)) menu.hidden = true; });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') menu.hidden = true; });
  show();

  box.appendChild(menu);
  box.appendChild(btn);
  function mount() { document.body.appendChild(box); }
  if (document.body) mount(); else document.addEventListener('DOMContentLoaded', mount);
})();
