// Rhythm-string parser: a port of tools/lilypond/rhythm_pdf.py (_TOKEN_RE, parse_rhythm,
// auto_bpb, count_row_from_cells) and tools/editor/rhythm_model.py (staff_events, sound_bars),
// so the page draws and plays an edited string without a server.
const RH = (() => {
  const TOK = /^(\(Α\)|\(A\)|\(ka\)|dum|tek|slap|ka|D|S|H|>|Δ|Α|A|r)(\d+\.?)?(\^>|>)?(:\d*)?(\[|\])?$/;
  const TUP = /^\{(\d+)(?::(\d+))?$/;
  const HEAD = {">": "dum", dum: "dum", D: "dum", "Δ": "tek", tek: "tek", "Α": "ka", A: "ka", ka: "ka", S: "slap", H: "slap", slap: "slap", r: null};
  const SUB = {1: [""], 2: ["", "+"], 4: ["", "e", "+", "a"]};
  const SYLL = {3: ["", "la", "li"]};
  const TRILL_DEFAULT = 32;
  const r6 = x => Math.round(x * 1e6) / 1e6;
  const gcd = (a, b) => b ? gcd(b, a % b) : a;
  const lcm = (a, b) => a / gcd(a, b) * b;
  const fmt = x => String(r6(x)).replace(".", ",");
  function ratio(n, k) { if (k == null) { k = 1; while (k * 2 < n) k *= 2; } return [n, k]; }
  function tok(raw) {
    const m = TOK.exec(raw);
    if (!m) throw new Error(`δεν διαβάζεται το «${raw}»`);
    const [, headRaw, dur, accent, trill, beam] = m;
    const middle = headRaw.startsWith("(");
    const head = middle ? headRaw.slice(1, -1) : headRaw;
    return {head, drum: HEAD[head], dur, accent: !!accent, middle, beam: beam || null,
            trill: trill == null ? null : (trill.length > 1 ? parseInt(trill.slice(1), 10) : TRILL_DEFAULT)};
  }
  const barsOf = rs => rs.split("|").map(s => s.trim()).filter(Boolean);
  function durations(rs) {
    const out = new Set(); let prev = "4";
    for (const raw of rs.replace(/\|/g, " ").split(/\s+/).filter(Boolean)) {
      const m = TOK.exec(raw); if (!m) continue;
      const d = m[2] || prev; prev = d;
      out.add(d.endsWith(".") ? 2 * parseInt(d, 10) : parseInt(d, 10));
    }
    return out;
  }
  function autoBpb(rs, den) {
    const ds = durations(rs); if (!ds.size) return 4;
    let l = 1; ds.forEach(d => { l = lcm(l, d); });
    return Math.max(1, Math.floor(l / den));
  }
  function cellsFor(dur, bpb, den) {
    const num = den * bpb;
    if (dur.endsWith(".")) {
      const b = parseInt(dur, 10);
      if ((3 * num) % (2 * b)) throw new Error(`η διάρκεια ${dur} δεν χωράει στο πλέγμα`);
      return (3 * num) / (2 * b);
    }
    const d = parseInt(dur, 10);
    if (num % d) throw new Error(`η διάρκεια ${dur} δεν χωράει στο πλέγμα`);
    return num / d;
  }
  function tubsCells(rs, bpb, den) {
    const bars = []; let prev = "4";
    for (const bs of barsOf(rs)) {
      if (bs === "%") { if (!bars.length) throw new Error("το % δεν έχει προηγούμενο μέτρο"); bars.push(null); continue; }
      const cells = []; let tup = null, gid = 0;
      for (const raw of bs.split(/\s+/)) {
        const tm = TUP.exec(raw);
        if (tm) { if (tup) throw new Error("τρίηχο μέσα σε τρίηχο"); gid++; tup = ratio(+tm[1], tm[2] ? +tm[2] : null); tup.push(gid); continue; }
        if (raw === "}") { if (!tup) throw new Error("«}» χωρίς «{3»"); tup = null; continue; }
        const t = tok(raw);
        if (t.middle && t.drum !== "ka") throw new Error(`οι παρενθέσεις μπαίνουν μόνο στο Α: «${raw}»`);
        if (t.trill && t.drum === null) throw new Error(`τρίλια σε παύση: «${raw}»`);
        const dur = t.dur || prev; prev = dur;
        const n = cellsFor(dur, bpb, den);
        if (tup) cells.push({glyph: t.drum, accent: t.accent, middle: t.middle, trill: !!t.trill, span: n * tup[1] / tup[0], tuplet: [tup[0], tup[1]], group: tup[2]});
        else if (t.drum === null) for (let i = 0; i < n; i++) cells.push(null);
        else { cells.push({glyph: t.drum, accent: t.accent, middle: t.middle, trill: !!t.trill}); for (let i = 1; i < n; i++) cells.push(null); }
      }
      if (tup) throw new Error("το τρίηχο δεν κλείνει με «}»");
      bars.push(cells);
    }
    if (!bars.length) throw new Error("κενός ρυθμός");
    return bars;
  }
  function counts(cells, bpb) {
    const pat = SUB[bpb]; if (!pat) throw new Error(`δεν υπάρχει μέτρημα για ${bpb} κουτάκια ανά χρόνο`);
    const out = []; let pos = 0, idx = 0, pg = null;
    for (const c of cells) {
      const span = c && c.span != null ? c.span : 1;
      const beatStart = Math.abs(pos - Math.round(pos)) < 1e-6 && Math.round(pos) % bpb === 0;
      const beatNo = Math.floor(Math.round(pos) / bpb) + 1;
      let lab;
      if (c && c.tuplet) {
        if (c.group !== pg) { idx = 0; pg = c.group; }
        const sy = SYLL[c.tuplet[0]] || [];
        lab = beatStart ? String(beatNo) : (idx < sy.length ? sy[idx] : ""); idx++;
      } else { pg = null; const sub = Math.round(pos) % bpb; lab = sub === 0 ? String(beatNo) : pat[sub]; }
      out.push([lab, span]); pos += span;
    }
    return out;
  }
  function staffEvents(rs) {
    const bars = []; let prev = "4";
    for (const bs of barsOf(rs)) {
      if (bs === "%") { bars.push(null); continue; }
      const ev = []; let tup = null, gid = 0;
      for (const raw of bs.split(/\s+/)) {
        const tm = TUP.exec(raw);
        if (tm) { tup = ratio(+tm[1], tm[2] ? +tm[2] : null); gid++; continue; }
        if (raw === "}") { tup = null; continue; }
        const t = tok(raw); const dur = t.dur || prev; prev = dur;
        const e = {drum: t.drum, dur, accent: t.accent, middle: t.middle, beam: t.beam};
        if (t.trill != null) e.trill = t.trill;
        if (tup) { e.tuplet = [tup[0], tup[1]]; e.group = gid; }
        ev.push(e);
      }
      bars.push(ev);
    }
    return bars;
  }
  function soundBars(rs, num, den) {
    const bars = []; let prev = "4";
    for (const bs of barsOf(rs)) {
      if (bs === "%") { if (!bars.length) throw new Error("το % δεν έχει προηγούμενο μέτρο"); bars.push(bars[bars.length - 1]); continue; }
      const events = [], groups = {}; let t = 0, tup = null, gid = 0, gs = 0;
      for (const raw of bs.split(/\s+/)) {
        const tm = TUP.exec(raw);
        if (tm) { tup = ratio(+tm[1], tm[2] ? +tm[2] : null); gid++; gs = t; continue; }
        if (raw === "}") { groups[String(gid)] = {start: r6(gs), end: r6(t)}; tup = null; continue; }
        const k = tok(raw); const dur = k.dur || prev; prev = dur;
        let beats = den / parseInt(dur, 10) * (dur.endsWith(".") ? 1.5 : 1);
        if (tup) beats *= tup[1] / tup[0];
        if (k.drum) {
          const ev = {t: r6(t), stroke: k.middle ? "kam" : k.drum, accent: k.accent};
          if (tup) ev.group = String(gid);
          if (k.trill != null) { ev.trill = k.trill; ev.dur = r6(beats); }
          events.push(ev);
        }
        t += beats;
      }
      bars.push({beats: r6(t), events, groups});
    }
    return bars;
  }
  // analyze(rhythm, "7/8") -> {meter, beats, bpb, bars, sound, errors: [], warnings: []}
  function analyze(rs, meter) {
    const out = {rhythm: rs, meter, beats: 4, bpb: null, bars: [], sound: [], errors: [], warnings: []};
    const mm = /^\s*(\d+)\s*\/\s*(\d+)\s*$/.exec(meter || "");
    if (!mm) { out.errors.push(`το μέτρο «${meter}» δεν είναι της μορφής N/D`); return out; }
    const num = +mm[1], den = +mm[2]; out.beats = num;
    rs = (rs || "").replace(/\s+/g, " ").trim(); out.rhythm = rs;
    if (!rs) { out.errors.push("κενός ρυθμός"); return out; }
    try {
      const bpb = autoBpb(rs, den); out.bpb = bpb;
      const sound = soundBars(rs, num, den); out.sound = sound;
      const evs = staffEvents(rs);
      let cells = null;
      try { cells = tubsCells(rs, bpb, den); } catch (e) { out.warnings.push("χωρίς πλέγμα TUBS: " + e.message); }
      evs.forEach((ev, i) => {
        if (ev === null) { out.bars.push({repeat: true}); return; }
        const bar = {repeat: false, events: ev};
        const c = cells && cells[i];
        if (c) {
          bar.cells = c.map(x => x === null ? null : Object.assign({glyph: x.glyph, accent: x.accent, middle: x.middle, trill: x.trill}, x.span != null ? {span: x.span} : {}));
          try { bar.counts = counts(c, bpb); } catch (e) { delete bar.cells; if (!out.warnings.length) out.warnings.push("χωρίς πλέγμα TUBS: " + e.message); }
        }
        out.bars.push(bar);
      });
      sound.forEach((b, i) => { if (Math.abs(b.beats - num) > 1e-6) out.errors.push(`το μέτρο ${i + 1} έχει ${fmt(b.beats)} από ${num} χρόνους (${num}/${den})`); });
    } catch (e) { out.errors.push(e.message); out.bars = []; out.sound = []; }
    return out;
  }
  return {analyze, tok};
})();
if (typeof module !== "undefined") module.exports = RH;
