#!/usr/bin/env python3
"""Convert rhythm-database entries into LilyPond `.ly` files (and compile to PDF).

Reads `process/music/rhythms.yaml` and emits one drum-staff + TUBS-table
file per variation under `process/music/rhythms/`. Each `.ly` is also
compiled with `lilypond` unless `--no-compile` is passed.

Rhythm-token grammar (sticky duration, carries across bars):
    <glyph>[duration][trailing-accent]
  glyph: > | Δ | Α | r
  duration: 4 | 8 | 16 | 2 | 1   (sticky; reuses previous when omitted)
  trailing-accent: > (only meaningful on Δ and Α; dum is always emphasized)
  bar separator: |

Each variation renders three rows under the staff per bar:
  1. Greek TUBS    — > δ Δ α Α   (case = accent: lower = unaccented, upper = accented)
  2. Latin TUBS    — D t T k K   (same convention; dum is always D)
  3. Counts        — 1 e + a 2 e + a ...  (BPB-aware subdivision labels)

Every cell at the end of a beat (i % BPB == BPB-1) gets a thicker right
divider so beat boundaries pop. The outer box closes the final right edge.

`boxes_per_beat` is per variation (default 4). Cell size, font, and divider
thickness auto-scale so total table width stays roughly constant.
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is required: pip install pyyaml")

REPO = Path(__file__).resolve().parents[2]
# rythmiko-toxo splits the rhythm database across rhythms/<slug>.yaml.
RHYTHMS_DIR = REPO / "rhythms"
OUT_DIR = REPO / "bundles"


def load_db():
    """Merge every rhythms/<slug>.yaml into a single dict keyed by slug."""
    if not RHYTHMS_DIR.is_dir():
        sys.exit(f"rhythms dir not found: {RHYTHMS_DIR}")
    db = {}
    for path in sorted(RHYTHMS_DIR.glob("*.yaml")):
        loaded = yaml.safe_load(path.read_text(encoding="utf-8"))
        if not isinstance(loaded, dict):
            print(f"[warn] {path.name}: top level must be a mapping; skipping", file=sys.stderr)
            continue
        for slug, body in loaded.items():
            if slug in db:
                print(f"[warn] duplicate slug {slug!r} (in {path.name})", file=sys.stderr)
            db[slug] = body
    return db

DEFAULT_BPB = 4

# Reference geometry: at BPB=2 cells are 3.5 staff-spaces square.
REFERENCE_BPB = 2
REFERENCE_CELL_SIZE = 3.5
REFERENCE_TUBS_FONT = 1
REFERENCE_COUNT_FONT = -2
REFERENCE_DIVIDER = 1.2
REFERENCE_OUTER = 1.2
DIVIDER_THICK_RATIO = 2.5      # how much thicker the every-Nth divider is

# Vertical layout: letters sit near the bottom of each cell with a small
# padding so they don't look crammed. The count row uses a SHORT cell so
# it visually hugs the TUBS row above.
TEXT_BOTTOM_PADDING_RATIO = 0.15  # padding from cell bottom = ratio * cell_height
COUNT_CELL_HEIGHT = 0.8           # staff-spaces; short cell -> compact count row

BAR_VSPACE = 1.7

GLYPH_TO_DRUM = {">": "dum", "Δ": "tek", "Α": "ka", "r": None}
GLYPH_TO_BELOW = {">": ">", "Δ": "Δ", "Α": "Α"}

# Per-cell rendering glyphs by output style.
def latin_glyph(cell):
    if cell is None:
        return " "
    g, a = cell["glyph"], cell["accent"]
    if g == "dum": return "D"
    if g == "tek": return "T" if a else "t"
    if g == "ka":  return "K" if a else "k"
    return " "


def greek_glyph(cell):
    if cell is None:
        return " "
    g, a = cell["glyph"], cell["accent"]
    if g == "dum": return ">"
    if g == "tek": return "Δ" if a else "δ"
    if g == "ka":  return "Α" if a else "α"
    return " "


SUBDIVISION_LABELS = {
    1: [""],
    2: ["", "+"],
    4: ["", "e", "+", "a"],
}

_TOKEN_RE = re.compile(r"([>ΔΑr])(\d+)?(>)?$")

TEMPLATE_HEAD = r"""\version "2.24.4"

\header {
  title = "__TITLE__"
  tagline = ##f
}

#(define darbuka-style '(
  (dum default #f -1)
  (tek default #f 1)
  (ka default #f 2)
  (slap cross #f 0)
))

drumPitchNames.dum = #'dum
drumPitchNames.tek = #'tek
drumPitchNames.ka = #'ka
drumPitchNames.slap = #'slap

% Square TUBS cell. Letter sits NEAR THE BOTTOM of the cell with a small
% padding (controlled by TEXT_BOTTOM_PADDING_RATIO in the Python side).
#(define-markup-command (tubsCell layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER
             \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

% Same as tubsCell but with a thicker right divider (every BPB-th cell).
#(define-markup-command (tubsCellThick layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER
             \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER_THICK__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

% Count-label cell. Same X width as tubsCell so columns align; SHORT Y
% extent so the row sits compactly under the TUBS rows. Label is also
% bottom-aligned within its short cell.
#(define-markup-command (countCell layout props label)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__COUNT_NEG_Y__ . __COUNT_POS_Y__)
             \translate #'(0 . __COUNT_TEXT_Y__)
             \halign #CENTER
             \fontsize #__COUNT_FONT__ #label
           \translate #'(__POS_HALF__ . __COUNT_NEG_Y__)
             \transparent
             \override #'(thickness . __DIVIDER__)
             \draw-line #'(0 . __COUNT_CELL_H__)
         }
       } #}))

\paper {
  top-margin = 40
  bottom-margin = 30
  left-margin = 25
  right-margin = 25
}

\layout {
  \context {
    \Score
    \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/4)
    \override MetronomeMark.padding = #8
    \override RehearsalMark.extra-offset = #'(0 . 8)
  }
  \context {
    \Staff
    \override StaffSymbol.staff-space = 4.5
  }
}

\score {
  \new DrumStaff \with {
    \override StaffSymbol.line-count = #3
    drumStyleTable = #(alist->hash-table darbuka-style)
  }
  {
    \drummode {
      \time __METER__
      \stemUp
      __DRUMMODE__
    }
  }
}

\markup {
  \column {
__TUBS_BLOCKS__
  }
}
"""

TUBS_BAR_BLOCK = r"""    \concat {
      \hspace #9
      \center-column {
        { \override #'(box-padding . 0) \override #'(thickness . __OUTER__) \box \concat { __TUBS_GREEK__ } }
        { \override #'(box-padding . 0) \override #'(thickness . __OUTER__) \box \concat { __TUBS_LATIN__ } }
        \concat { __COUNT__ }
      }
    }"""


def cells_for_duration(dur: int, bpb: int, meter_den: int) -> int:
    """Cells occupied by a note of LilyPond duration `dur` in a BPB grid."""
    num = meter_den * bpb
    if num % dur != 0:
        raise ValueError(
            f"duration {dur} does not fit cleanly in {bpb}-per-beat grid "
            f"with denominator {meter_den}"
        )
    return num // dur


def parse_rhythm(rhythm_str: str, bpb: int, meter_den: int):
    """Returns list of (drummode_tokens, cells) per bar.

    `cells` is a list with one entry per grid cell. Each entry is either
    None (sustain or rest -> blank) or a dict {glyph, accent}.
    """
    bars = []
    prev_duration = "4"

    for bar_str in rhythm_str.split("|"):
        bar_str = bar_str.strip()
        if not bar_str:
            continue
        drummode = []
        cells = []
        for raw in bar_str.split():
            m = _TOKEN_RE.match(raw)
            if not m:
                raise ValueError(f"cannot parse token {raw!r}")
            glyph, duration, accent = m.group(1), m.group(2), m.group(3)
            if duration is None:
                duration = prev_duration
            prev_duration = duration

            if glyph == "r":
                drummode.append(f"r{duration}")
            elif glyph == ">":
                drummode.append(f"dum{duration}_>")
            else:
                tok = f"{GLYPH_TO_DRUM[glyph]}{duration}_{GLYPH_TO_BELOW[glyph]}"
                if accent:
                    tok += "^>"
                drummode.append(tok)

            cell_count = cells_for_duration(int(duration), bpb, meter_den)
            if glyph == "r":
                cells.extend([None] * cell_count)
            else:
                drum = GLYPH_TO_DRUM[glyph]
                cells.append({"glyph": drum, "accent": bool(accent)})
                cells.extend([None] * (cell_count - 1))
        bars.append((drummode, cells))

    if not bars:
        raise ValueError("empty rhythm")
    return bars


def count_row(meter: str, bpb: int):
    num, _ = (int(x) for x in meter.split("/"))
    if bpb not in SUBDIVISION_LABELS:
        raise ValueError(f"no subdivision labels for boxes_per_beat={bpb}")
    pattern = SUBDIVISION_LABELS[bpb]
    labels = []
    for beat in range(1, num + 1):
        for i, suffix in enumerate(pattern):
            labels.append(str(beat) if i == 0 else suffix)
    return labels


def render_tubs_row(cells, glyph_func, bpb):
    """Render one TUBS row, alternating thin/thick dividers at beat ends."""
    parts = []
    last = len(cells) - 1
    for i, c in enumerate(cells):
        glyph = glyph_func(c)
        is_beat_end = (i + 1) % bpb == 0
        is_last = i == last
        cmd = "tubsCellThick" if (is_beat_end and not is_last) else "tubsCell"
        parts.append(f'\\{cmd} "{glyph}"')
    return " ".join(parts)


def render_count_row(labels):
    return " ".join(f'\\countCell "{c}"' for c in labels)


def variation_filename(slug, var):
    parts = [var.get("date", "undated"), slug]
    line = var.get("line")
    if line is not None:
        parts.append(f"line-{line}")
    return "-".join(str(p) for p in parts) + ".ly"


def cell_geometry(bpb: int):
    cell_size = REFERENCE_CELL_SIZE * REFERENCE_BPB / bpb
    half = cell_size / 2.0
    font_offset = round(2 * math.log2(cell_size / REFERENCE_CELL_SIZE))
    tubs_font = REFERENCE_TUBS_FONT + font_offset
    count_font = REFERENCE_COUNT_FONT + font_offset
    scale = cell_size / REFERENCE_CELL_SIZE
    divider = REFERENCE_DIVIDER * scale
    outer = REFERENCE_OUTER * scale
    divider_thick = divider * DIVIDER_THICK_RATIO

    # Bottom-aligned text positions (baseline = -half + padding * cell_height).
    tubs_text_y = -half + TEXT_BOTTOM_PADDING_RATIO * cell_size
    count_half_y = COUNT_CELL_HEIGHT / 2.0
    count_text_y = -count_half_y + TEXT_BOTTOM_PADDING_RATIO * COUNT_CELL_HEIGHT

    return {
        "cell_size": cell_size,
        "half": half,
        "tubs_font": tubs_font,
        "count_font": count_font,
        "divider": divider,
        "divider_thick": divider_thick,
        "outer": outer,
        "tubs_text_y": tubs_text_y,
        "count_neg_y": -count_half_y,
        "count_pos_y": count_half_y,
        "count_cell_h": COUNT_CELL_HEIGHT,
        "count_text_y": count_text_y,
    }


def render_ly(slug: str, display: str, var: dict) -> str:
    meter = var["meter"]
    bpb = int(var.get("boxes_per_beat", DEFAULT_BPB))
    meter_num, meter_den = (int(x) for x in meter.split("/"))

    bars = parse_rhythm(var["rhythm"], bpb, meter_den)
    counts = count_row(meter, bpb)
    expected_cells = meter_num * bpb

    geom = cell_geometry(bpb)

    drummode_pieces = []
    tubs_blocks = []
    for i, (bar_drummode, cells) in enumerate(bars):
        if len(cells) != expected_cells:
            sys.stderr.write(
                f"warning: {slug} {var.get('date')} bar {i+1}: cells {len(cells)} "
                f"!= expected {expected_cells}; check rhythm against meter\n"
            )
        drummode_pieces.append(" ".join(bar_drummode))
        block = (TUBS_BAR_BLOCK
                 .replace("__TUBS_GREEK__", render_tubs_row(cells, greek_glyph, bpb))
                 .replace("__TUBS_LATIN__", render_tubs_row(cells, latin_glyph, bpb))
                 .replace("__COUNT__", render_count_row(counts))
                 .replace("__OUTER__", f"{geom['outer']:.3f}"))
        tubs_blocks.append(block)

    drummode_body = " | ".join(drummode_pieces) + " | \\break"

    separator = f"\n    \\vspace #{BAR_VSPACE}\n"
    tubs_section = separator.join(tubs_blocks)

    out = (TEMPLATE_HEAD
           .replace("__TITLE__", display)
           .replace("__METER__", meter)
           .replace("__DRUMMODE__", drummode_body)
           .replace("__TUBS_BLOCKS__", tubs_section)
           .replace("__CELL_SIZE__", f"{geom['cell_size']:.4f}")
           .replace("__NEG_HALF__", f"{-geom['half']:.4f}")
           .replace("__POS_HALF__", f"{geom['half']:.4f}")
           .replace("__TUBS_FONT__", str(geom["tubs_font"]))
           .replace("__COUNT_FONT__", str(geom["count_font"]))
           .replace("__DIVIDER_THICK__", f"{geom['divider_thick']:.3f}")
           .replace("__DIVIDER__", f"{geom['divider']:.3f}")
           .replace("__TUBS_TEXT_Y__", f"{geom['tubs_text_y']:.4f}")
           .replace("__COUNT_NEG_Y__", f"{geom['count_neg_y']:.4f}")
           .replace("__COUNT_POS_Y__", f"{geom['count_pos_y']:.4f}")
           .replace("__COUNT_CELL_H__", f"{geom['count_cell_h']:.4f}")
           .replace("__COUNT_TEXT_Y__", f"{geom['count_text_y']:.4f}"))
    return out


def write_variation(slug: str, display: str, var: dict) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / variation_filename(slug, var)
    path.write_text(render_ly(slug, display, var), encoding="utf-8")
    return path


def compile_ly(path: Path) -> bool:
    if not shutil.which("lilypond"):
        sys.stderr.write("  lilypond not found on PATH; skipping compile\n")
        return False
    try:
        result = subprocess.run(
            ["lilypond", path.name],
            cwd=path.parent,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        sys.stderr.write(f"  lilypond timed out compiling {path.name}\n")
        return False
    if result.returncode != 0:
        tail = (result.stderr or result.stdout).strip().splitlines()[-5:]
        sys.stderr.write("  lilypond failed:\n    " + "\n    ".join(tail) + "\n")
        return False
    print(f"  compiled {path.with_suffix('.pdf').name}")
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rhythm", help="rhythm slug to render; omit for all")
    ap.add_argument("--date", help="filter by variation date")
    ap.add_argument("--line", help="filter by line within date (string match)")
    ap.add_argument("--no-compile", action="store_true",
                    help="skip the lilypond compile step")
    args = ap.parse_args()

    db = load_db()
    if not db:
        sys.exit(f"no rhythms found in {RHYTHMS_DIR}")

    written = []
    for slug, body in db.items():
        if args.rhythm and slug != args.rhythm:
            continue
        display = body.get("display", slug)
        for var in body.get("variations", []):
            if args.date and var.get("date") != args.date:
                continue
            if args.line is not None and str(var.get("line")) != str(args.line):
                continue
            path = write_variation(slug, display, var)
            print(f"wrote {path.relative_to(REPO)}")
            if not args.no_compile:
                compile_ly(path)
            written.append(path)

    if not written:
        sys.exit("no variations matched the filter")
    return 0


if __name__ == "__main__":
    sys.exit(main())
