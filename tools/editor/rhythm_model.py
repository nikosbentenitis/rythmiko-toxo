"""Parse a rhythm YAML for the local editor: diagnostics, notation, sound.

Everything is parsed with the LilyPond converter's own grammar
(tools/lilypond/rhythm_pdf.py: `_TOKEN_RE`, `_TUPLET_OPEN_RE`,
`parse_rhythm`, `auto_bpb`, `count_row_from_cells`), so tuplets `{3 … }`
and the τρίλια `Α8:` work here although the web validator's Pyodide
parser does not know them yet.

    analyze(yaml_text, slug) -> {
      "diagnostics": [{severity: ok|warn|error, where, message}],
      "rhythm": {slug, display, meter, tempo, comment, variations: [
          {id, rhythm, comment, meter, beats, bpb,
           bars: [...],      # notation: events for the VexFlow staff, cells + counts for TUBS
           sound: [...]}]}}  # per bar {beats, events: [{t, stroke, accent, group?, trill?, dur?}], groups}

`bars` is the shape notation.js (the validator's renderStaff/renderTubs)
draws; `sound` is the shape player.js schedules. Both come from the
rhythm-scan skill's notation.py and rhythm_events.py, ported here so the
editor depends on nothing outside this repo.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "lilypond"))
import rhythm_pdf as rp  # noqa: E402
import yaml  # noqa: E402

VAR_KEY = re.compile(r"^v\d+$")
METER = re.compile(r"^\s*(\d+)\s*/\s*(\d+)\s*$")


def staff_events(rhythm_str: str):
    """Per bar the token list for the staff renderer (None for a `%` bar)."""
    bars, prev = [], "4"
    for bar_str in rhythm_str.split("|"):
        bar_str = bar_str.strip()
        if not bar_str:
            continue
        if bar_str == rp.REPEAT_BAR:
            bars.append(None)
            continue
        ev, tup, gid = [], None, 0
        for raw in bar_str.split():
            tm = rp._TUPLET_OPEN_RE.match(raw)
            if tm:
                tup = rp._tuplet_ratio(int(tm.group(1)), int(tm.group(2)) if tm.group(2) else None)
                gid += 1
                continue
            if raw == rp._TUPLET_CLOSE:
                tup = None
                continue
            m = rp._TOKEN_RE.match(raw)
            if not m:
                raise ValueError(f"cannot parse token {raw!r}")
            head_raw, dur, accent, trill, beam = m.groups()
            middle = head_raw.startswith("(")
            head = head_raw[1:-1] if middle else head_raw
            dur = dur or prev
            prev = dur
            e = {"drum": rp.HEAD_TO_DRUM[head], "dur": dur, "accent": bool(accent),
                 "middle": middle, "beam": beam}
            if trill is not None:
                e["trill"] = int(trill[1:]) if len(trill) > 1 else rp.TRILL_DEFAULT
            if tup:
                e["tuplet"] = list(tup)
                e["group"] = gid
            ev.append(e)
        bars.append(ev)
    return bars


def sound_bars(rhythm_str: str, num: int, den: int):
    """Timed strokes per bar, in beats (quarter = 1 when den = 4) from bar start."""
    bars, prev = [], "4"
    for bar_str in rhythm_str.split("|"):
        bar_str = bar_str.strip()
        if not bar_str:
            continue
        if bar_str == rp.REPEAT_BAR:
            if not bars:
                raise ValueError("'%' repeat bar has no preceding bar")
            bars.append(bars[-1])
            continue
        events, t, tup = [], 0.0, None
        groups, gid, gstart = {}, 0, 0.0
        for raw in bar_str.split():
            tm = rp._TUPLET_OPEN_RE.match(raw)
            if tm:
                tup = rp._tuplet_ratio(int(tm.group(1)), int(tm.group(2)) if tm.group(2) else None)
                gid += 1
                gstart = t
                continue
            if raw == rp._TUPLET_CLOSE:
                groups[str(gid)] = {"start": round(gstart, 6), "end": round(t, 6)}
                tup = None
                continue
            m = rp._TOKEN_RE.match(raw)
            if not m:
                raise ValueError(f"cannot parse token {raw!r}")
            head_raw, dur, accent, trill, _beam = m.groups()
            middle = head_raw.startswith("(")
            head = head_raw[1:-1] if middle else head_raw
            dur = dur or prev
            prev = dur
            dotted = dur.endswith(".")
            beats = den / int(dur.rstrip(".")) * (1.5 if dotted else 1.0)
            if tup:
                beats *= tup[1] / tup[0]
            drum = rp.HEAD_TO_DRUM[head]
            if drum:
                ev = {"t": round(t, 6), "stroke": "kam" if middle else drum, "accent": bool(accent)}
                if tup:
                    ev["group"] = str(gid)
                if trill is not None:
                    ev["trill"] = int(trill[1:]) if len(trill) > 1 else rp.TRILL_DEFAULT
                    ev["dur"] = round(beats, 6)
                events.append(ev)
            t += beats
        bars.append({"beats": round(t, 6), "events": events, "groups": groups})
    return bars


def _variation(node: dict, vid: str, var: dict, diags: list, where: str):
    meter = str(var.get("meter") or node.get("meter") or "")
    mm = METER.match(meter)
    if not mm:
        diags.append({"severity": "error", "where": where, "message": f"meter {meter!r} is not N/D (e.g. 7/8)"})
        return None
    num, den = int(mm.group(1)), int(mm.group(2))
    meter = f"{num}/{den}"
    rs = var.get("rhythm")
    out = {"id": vid, "rhythm": rs or "", "comment": var.get("comment") or "",
           "meter": meter, "beats": num, "bpb": None, "bars": [], "sound": []}
    if not rs or not isinstance(rs, str):
        diags.append({"severity": "error", "where": where, "message": "no 'rhythm' string"})
        return out
    try:
        if var.get("boxes_per_beat") is not None:
            bpb = int(var["boxes_per_beat"])
        elif node.get("boxes_per_beat") is not None:
            bpb = int(node["boxes_per_beat"])
        else:
            bpb = rp.auto_bpb({**node, "meter": meter}, meter)
        out["bpb"] = bpb
        sound = sound_bars(rs, num, den)
        out["sound"] = sound
        evs = staff_events(rs)
        try:
            parsed = rp.parse_rhythm(rs, bpb, den)
        except Exception as e:  # TUBS grid could not be built: staff only
            parsed = None
            diags.append({"severity": "warn", "where": where, "message": f"TUBS grid skipped: {e}"})
        for i, ev in enumerate(evs):
            ly_cells = parsed[i] if parsed and i < len(parsed) else (None, None)
            if ev is None:
                out["bars"].append({"repeat": True})
                continue
            bar = {"repeat": False, "events": ev}
            cells = ly_cells[1] if ly_cells else None
            if cells is not None:
                bar["cells"] = [None if c is None else {k: c.get(k) for k in ("glyph", "accent", "middle", "trill", "span") if k in c}
                                for c in cells]
                bar["counts"] = [[lab, span] for lab, span in rp.count_row_from_cells(cells, bpb)]
            out["bars"].append(bar)
        bad = False
        for i, b in enumerate(sound):
            if abs(b["beats"] - num) > 1e-6:
                bad = True
                diags.append({"severity": "error", "where": f"{where} bar {i + 1}",
                              "message": f"bar {i + 1} is {b['beats']:g} of {num} beats ({meter}): it does not fill the meter"})
        if not bad:
            diags.append({"severity": "ok", "where": where,
                          "message": f"{meter}, bpb {bpb}, {len(sound)} bar(s), every bar fills the meter"})
    except Exception as e:
        diags.append({"severity": "error", "where": where, "message": str(e)})
    return out


def analyze(text: str, slug: str | None = None) -> dict:
    diags = []
    res = {"diagnostics": diags, "rhythm": None}
    try:
        db = yaml.safe_load(text)
    except yaml.YAMLError as e:
        diags.append({"severity": "error", "where": "YAML", "message": f"YAML parse error: {e}"})
        return res
    if not isinstance(db, dict) or len(db) != 1:
        diags.append({"severity": "error", "where": "YAML",
                      "message": "the file must hold exactly one top-level key: the rhythm's slug"})
        return res
    key, node = next(iter(db.items()))
    if slug and key != slug:
        diags.append({"severity": "error", "where": "YAML",
                      "message": f"top-level key {key!r} must match the file name {slug!r}"})
        return res
    if not isinstance(node, dict):
        diags.append({"severity": "error", "where": key, "message": "the rhythm is not a mapping"})
        return res
    for req in ("display", "meter", "variations"):
        if req not in node:
            diags.append({"severity": "error", "where": key, "message": f"missing required key '{req}'"})
    variations = node.get("variations") or {}
    if not isinstance(variations, dict) or not variations:
        diags.append({"severity": "error", "where": key, "message": "'variations' must hold at least one vN"})
        variations = {}
    try:
        tempo = int(node.get("tempo") or 90)
    except (TypeError, ValueError):
        tempo = 90
        diags.append({"severity": "warn", "where": key, "message": "tempo is not a number; using 90"})
    r = {"slug": key, "display": str(node.get("display", key)), "meter": str(node.get("meter", "")),
         "tempo": tempo, "comment": node.get("comment") or "", "variations": []}
    for vid, var in variations.items():
        where = f"{key}.{vid}"
        if not VAR_KEY.match(str(vid)):
            diags.append({"severity": "warn", "where": where, "message": "variation keys are v1, v2, …"})
        if not isinstance(var, dict):
            diags.append({"severity": "error", "where": where, "message": "variation is not a mapping"})
            continue
        v = _variation(node, str(vid), var, diags, where)
        if v:
            r["variations"].append(v)
    res["rhythm"] = r
    return res


def has_errors(res: dict) -> bool:
    return any(d["severity"] == "error" for d in res["diagnostics"])


def structural_errors(res: dict) -> list:
    """Errors that make the file unusable: YAML or rhythm-level ones, not a
    variation whose bar is a beat short (that one may be saved mid-lesson)."""
    return [d for d in res["diagnostics"] if d["severity"] == "error" and "." not in d["where"]]
