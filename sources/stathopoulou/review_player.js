// Darbuka player, copied from tools/editor/static/player.js (branch local-editor) with the samples embedded.
//
// Ported from the rhythm-scan skill's player pages (build_player.py and
// build_public.py): the same Freesound samples and manifest (samples/),
// the same gains and accent boost, the same τρίλια placement (roll of
// `trill_strokes` hits from the written onset; inside a tuplet the later
// notes of the group are spread evenly up to `trill_last` of the span),
// the same look-ahead scheduler, and the iPhone handling of the public
// page (AudioContext made inside the tap, a looping silent <audio> so the
// mute switch does not silence it, a screen wake lock while playing).
//
// Differences from the skill's player: the plan is rebuilt from whatever rhythm the editor hands over (setRhythm),
// and the plan can loop forever.
//
//   Player.setRhythm(rhythm)   rhythm = analyze()['rhythm'] from the server; variation.sound are the timed bars,
//                              variation.bars the drawn bars (their _els are the SVG note groups to light up)
//   Player.play() / stop() / toggle(); Player.bpm = 96; Player.loop = true; Player.reps = 2;
//   Player.only = 3 (variation index) or null for all variations in order
//   Player.onchange = fn(state)  state = {playing, variation, rep, bar, beat, error}
const Player = (() => {
  let BANK = null, raw = {}, buffers = {}, ctx = null, bankReady = null;
  const rr = {};
  // Samples and manifest are embedded in the page (SAMPLES, MANIFEST), not fetched.
  const loadBank = Promise.resolve().then(() => {
    BANK = MANIFEST;
    Object.entries(SAMPLES).forEach(([n, b64]) => {
      const bin = atob(b64), u8 = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i);
      raw[n] = u8.buffer;
    });
  });

  const IS_IOS = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  function silentWav(seconds) {          // 8 kHz, 8-bit mono silence, built in memory
    const n = 8000 * seconds, buf = new ArrayBuffer(44 + n), v = new DataView(buf), u8 = new Uint8Array(buf);
    const str = (o, s) => { for (let i = 0; i < s.length; i++) v.setUint8(o + i, s.charCodeAt(i)); };
    str(0, 'RIFF'); v.setUint32(4, 36 + n, true); str(8, 'WAVE'); str(12, 'fmt '); v.setUint32(16, 16, true);
    v.setUint16(20, 1, true); v.setUint16(22, 1, true); v.setUint32(24, 8000, true); v.setUint32(28, 8000, true);
    v.setUint16(32, 1, true); v.setUint16(34, 8, true); str(36, 'data'); v.setUint32(40, n, true);
    u8.fill(128, 44);
    return URL.createObjectURL(new Blob([buf], { type: 'audio/wav' }));
  }
  let unlockEl = null;
  function unlockIOS() {
    if (!IS_IOS) return;
    try {
      if (!unlockEl) { unlockEl = new Audio(silentWav(2)); unlockEl.loop = true; unlockEl.setAttribute('playsinline', ''); unlockEl.volume = 0.01; }
      const pr = unlockEl.play(); if (pr && pr.catch) pr.catch(() => {});
    } catch (e) {}
  }
  // Must run synchronously inside the tap (iOS).
  function ensureCtx() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return bankReady; }
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === 'suspended') ctx.resume();
    try { const b = ctx.createBuffer(1, 1, 22050); const s0 = ctx.createBufferSource(); s0.buffer = b; s0.connect(ctx.destination); s0.start(0); } catch (e) {}
    bankReady = loadBank.then(() => Promise.all(Object.entries(raw).map(([n, ab]) =>
      new Promise((res, rej) => ctx.decodeAudioData(ab.slice(0), b => { buffers[n] = b; res(); }, rej)))));
    return bankReady;
  }
  function pick(stroke) {
    const names = BANK.strokes[stroke] || BANK.strokes.tek;
    rr[stroke] = rr[stroke] || 0;
    return buffers[names[rr[stroke]++ % names.length]];
  }
  function hit(buffer, when, gain) {
    if (!buffer) return;
    const src = ctx.createBufferSource(); src.buffer = buffer;
    const g = ctx.createGain(); g.gain.value = gain;
    src.connect(g).connect(ctx.destination);
    src.start(Math.max(ctx.currentTime, when));
  }

  // One bar's hits (build_player.py barHits), each carrying the SVG
  // element of its drawn note so it can light up as it sounds.
  function barHits(bar, drawn) {
    const N = Math.max(2, BANK.trill_strokes || 3), LAST = BANK.trill_last || 0.8;
    const els = drawn && drawn.events && drawn._els ?drawn.events.map((e, i) => [e, drawn._els[i]]).filter(([e]) => e.drum !== null).map(([, el]) => el) : [];
    const out = [], retimed = new Map(), elOf = new Map();
    bar.events.forEach((e, i) => elOf.set(e, els[i] || null));
    for (const e of bar.events) {
      if (!e.trill) continue;
      const grp = e.group ? (bar.groups || {})[e.group] : null;
      const later = grp ? bar.events.filter(x => x.group === e.group && x.t > e.t).sort((a, b) => a.t - b.t) : [];
      const step = later.length ? (LAST * (grp.end - e.t)) / (N + later.length - 1) : e.dur / N;
      for (let i = 0; i < N; i++) out.push({ t: e.t + i * step, stroke: 'trill', accent: false, gmul: 0.7 + 0.3 * i / (N - 1), el: elOf.get(e) });
      later.forEach((x, j) => retimed.set(x, e.t + (N + j) * step));
    }
    for (const e of bar.events) {
      if (e.trill) continue;
      out.push({ t: retimed.has(e) ? retimed.get(e) : e.t, stroke: e.stroke, accent: e.accent, gmul: 1, el: elOf.get(e) });
    }
    return out.sort((a, b) => a.t - b.t);
  }

  const P = { bpm: 90, loop: true, reps: 1, only: null, onchange: null, rhythm: null, playing: false };
  let timer = null, raf = null, wake = null, stalePlan = false;
  let anchorTime = 0, anchorBeat = 0, plan = [], pi = 0, barStart = 0, hits = [], idx = 0, marks = [], flashes = [], hotEl = null;
  const LOOKAHEAD = 0.12, TICK = 25;
  const timeAt = b => anchorTime + (b - anchorBeat) * 60 / P.bpm;
  const beatAt = t => anchorBeat + (t - anchorTime) * P.bpm / 60;
  const emit = s => { if (P.onchange) P.onchange(Object.assign({ playing: P.playing }, s || {})); };

  function buildPlan() {
    plan = [];
    if (!P.rhythm) return;
    P.rhythm.variations.forEach((v, vi) => {
      if (P.only !== null && P.only !== vi) return;
      if (!v.sound || !v.sound.length) return;
      for (let rep = 0; rep < P.reps; rep++) v.sound.forEach((bar, bi) => plan.push({ vi, rep, bi, bar, drawn: (v.bars || [])[bi] }));
    });
  }
  function loadBar() {
    const p = plan[pi];
    hits = barHits(p.bar, p.drawn); idx = 0;
    for (let b = 0; b < Math.ceil(p.bar.beats); b++) marks.push({ time: timeAt(barStart + b), beat: b, vi: p.vi, rep: p.rep, bar: p.bi });
  }
  function schedule() {
    const horizon = ctx.currentTime + LOOKAHEAD;
    for (;;) {
      if (!plan.length) { stop(true); return; }
      if (idx >= hits.length) {
        barStart += plan[pi].bar.beats; pi++;
        if (pi >= plan.length) {
          if (P.loop) { pi = 0; if (stalePlan) { stalePlan = false; buildPlan(); if (!plan.length) { stop(true); return; } } }
          else { if (ctx.currentTime > timeAt(barStart)) stop(true); return; }
        }
        loadBar();
        if (!hits.length) continue;
      }
      const e = hits[idx]; const when = timeAt(barStart + e.t);
      if (when >= horizon) break;
      idx++;
      if (when < ctx.currentTime - 0.05) continue;
      const g = (BANK.gain[e.stroke] || 0.5) * e.gmul * ((e.accent && e.stroke !== 'dum' && e.stroke !== 'trill') ? (BANK.accent_gain || 2) : 1);
      hit(pick(e.stroke), when, g);
      if (e.el) flashes.push({ time: when, el: e.el });
    }
  }
  function setHot(el) { if (hotEl && hotEl !== el) hotEl.classList.remove('hot'); if (el) el.classList.add('hot'); hotEl = el; }
  function paint() {
    if (!P.playing) return;
    const now = ctx.currentTime; let cur = null, fl = null;
    while (marks.length && marks[0].time <= now) cur = marks.shift();
    while (flashes.length && flashes[0].time <= now) fl = flashes.shift();
    if (fl) setHot(fl.el);
    if (cur) emit({ variation: cur.vi, rep: cur.rep, bar: cur.bar, beat: cur.beat });
    raf = requestAnimationFrame(paint);
  }
  async function play() {
    if (P.playing) return;
    buildPlan(); stalePlan = false;
    if (!plan.length) { emit({ error: 'Nothing to play: the rhythm has errors.' }); return; }
    unlockIOS();
    const ready = ensureCtx();
    try { await ready; } catch (e) { emit({ error: 'Could not load the drum samples: ' + e.message }); return; }
    if (ctx.state === 'suspended') await ctx.resume();
    P.playing = true;
    anchorTime = ctx.currentTime + 0.1; anchorBeat = 0; barStart = 0; marks = []; flashes = []; pi = 0; loadBar();
    schedule(); timer = setInterval(schedule, TICK); raf = requestAnimationFrame(paint);
    try { if (navigator.wakeLock) navigator.wakeLock.request('screen').then(l => { wake = l; }).catch(() => {}); } catch (e) {}
    emit({});
  }
  function stop(finished) {
    if (!P.playing && !timer) return;
    P.playing = false; clearInterval(timer); timer = null; cancelAnimationFrame(raf);
    try { if (unlockEl) unlockEl.pause(); } catch (e) {}
    flashes = []; marks = []; setHot(null);
    try { if (wake) { wake.release(); wake = null; } } catch (e) {}
    emit({ finished: !!finished });
  }
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && P.playing && navigator.wakeLock) navigator.wakeLock.request('screen').then(l => { wake = l; }).catch(() => {});
  });
  P.play = play;
  P.stop = () => stop(false);
  P.toggle = () => (P.playing ? stop(false) : play());
  P.restart = () => { if (P.playing) { stop(false); play(); } };
  P.setBpm = nb => {
    if (P.playing) { const now = ctx.currentTime; anchorBeat = beatAt(now); anchorTime = now; }
    P.bpm = nb;
  };
  // A new parse (every edit) takes effect at the next pass, so typing does not restart the beat.
  P.setRhythm = r => { P.rhythm = r; stalePlan = true; };
  P.bankReady = () => loadBank.then(() => ({ samples: Object.keys(raw), manifest: BANK }));
  return P;
})();
