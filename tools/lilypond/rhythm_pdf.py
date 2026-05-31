#!/usr/bin/env python3
"""Build a single PDF that bundles one or more rhythm variations.

Usage:
    rhythm_pdf.py --title "TITLE" SPEC [SPEC...]
where SPEC is `<slug>-<variation>` (e.g. aptaliko-v1, kasik_havasi-v2).

Each spec becomes its own section in the PDF: a heading with the
rhythm's display name + variation tag, the music staff, then the
Greek / Latin TUBS rows + count row. The user-given title is the PDF
title at the top of page 1.

Rhythms live in `process/music/rhythms.yaml`. Output lands at
`process/music/rhythms/bundles/<slugified-title>.{ly,pdf}` and the PDF
opens automatically (unless --no-open is passed).
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is required: pip install pyyaml")

REPO = Path(__file__).resolve().parents[2]
# rythmiko-toxo splits the rhythm database across rhythms/<slug>.yaml.
# load_db() walks the directory and merges the per-file maps in memory.
RHYTHMS_DIR = REPO / "rhythms"
OUT_DIR = REPO / "bundles"


def load_db():
    """Merge every rhythms/<slug>.yaml into a single dict keyed by slug.

    Each file is expected to be `<slug>: { display, meter, variations: {...} }`.
    Returns the unified mapping so the rest of the toolchain can operate on
    it identically to the old monolithic rhythms.yaml.
    """
    if not RHYTHMS_DIR.is_dir():
        sys.exit(f"rhythms dir not found: {RHYTHMS_DIR}")
    db = {}
    for path in sorted(RHYTHMS_DIR.glob("*.yaml")):
        text = path.read_text(encoding="utf-8")
        loaded = yaml.safe_load(text)
        if not isinstance(loaded, dict):
            print(f"[warn] {path.name}: top level must be a mapping; skipping", file=sys.stderr)
            continue
        for slug, body in loaded.items():
            if slug in db:
                print(f"[warn] duplicate slug {slug!r} (in {path.name})", file=sys.stderr)
            db[slug] = body
    return db

DEFAULT_BPB = 4

REFERENCE_BPB = 2
REFERENCE_CELL_SIZE = 3.5
REFERENCE_TUBS_FONT = 1
REFERENCE_COUNT_FONT = -2
REFERENCE_DIVIDER = 1.2
REFERENCE_OUTER = 1.2
DIVIDER_THICK_RATIO = 2.5

TEXT_BOTTOM_PADDING_RATIO = 0.15
COUNT_CELL_HEIGHT = 0.8

BAR_VSPACE = 1.7
SECTION_VSPACE = 0.5  # space between rhythm sections in the bundle

# 1 markup staff-space at default global staff-size (20pt) is 5pt = 1.764mm.
# Used to convert the (staff-space-denominated) TUBS cell width into the
# (millimetre-denominated) paper line-width so the music staff is forced to
# the same width as the TUBS row.
STAFF_SPACE_MM = 5.0 / 72 * 25.4   # ≈ 1.764 mm

# Indent allocated to the instrumentName / variation-number column, in
# markup staff-spaces.
LABEL_INDENT_SP = 3.0

# Layout presets — staff size, cell scale, and font offsets. Use via
# --variant A|B|C. Default (no variant) preserves the previous behavior.
LAYOUT_PRESETS = {
    "A": {  # modest: pentagram a bit bigger, boxes a bit smaller
        "staff_space": 5.5, "cell_scale": 0.85,
        "tubs_font_offset": -1, "count_font_offset": -1,
    },
    "B": {  # strong: pentagram clearly larger, compact boxes
        "staff_space": 6.5, "cell_scale": 0.70,
        "tubs_font_offset": -2, "count_font_offset": -2,
    },
    "C": {  # extreme: pentagram dominant, tiny boxes
        "staff_space": 7.5, "cell_scale": 0.55,
        "tubs_font_offset": -3, "count_font_offset": -3,
    },
}
DEFAULT_LAYOUT = LAYOUT_PRESETS["C"]   # adopted as default

# Input glyph language. The user may use either the symbol notation
#   >  Δ  Α (or A)  S (or H)  r
# or the word notation
#   dum (or D)  tek  ka  slap  r
# Latin `A` is accepted as an alias for the Greek kah `Α` (they look
# identical in most fonts), including the middle-finger form `(A)`.
# Slap renders as a cross notehead on the middle line (the darbuka-style
# `(slap cross #f 0)` entry in the preamble, matching the old reference
# .ly files). Accent (above) is the trailing `>` after duration in symbol
# notation OR the explicit `^>` in word notation. Both render as `^>` in
# LilyPond.
HEAD_TO_DRUM = {
    ">": "dum", "dum": "dum", "D": "dum",
    "Δ": "tek", "tek": "tek",
    "Α": "ka",  "A": "ka",  "ka": "ka",
    "S": "slap", "H": "slap", "slap": "slap",
    "r": None,
}
HEAD_TO_BELOW = {
    ">": ">", "dum": ">", "D": ">",
    "Δ": "Δ", "tek": "Δ",
    "Α": "Α", "A": "Α", "ka": "Α",
    "S": "S", "H": "S", "slap": "S",
}

SUBDIVISION_LABELS = {
    1: [""],
    2: ["", "+"],
    4: ["", "e", "+", "a"],
}

# Longest alternatives first so e.g. `dum` is preferred over `D`.
# Duration accepts an optional trailing `.` for a dotted note (1.5× base
# length), matching LilyPond's own duration syntax (e.g. `tek8.`).
# Wrapping a kah head in parens — `(Α)`, `(A)` or `(ka)` — marks the
# middle-finger kah variant; the TUBS letter renders inside a circle.
_TOKEN_RE = re.compile(
    r"(\(Α\)|\(A\)|\(ka\)|dum|tek|slap|ka|D|S|H|>|Δ|Α|A|r)"
    r"(\d+\.?)?(\^>|>)?(\[|\])?$"
)

# LilyPond identifiers can only contain letters, so digit-bearing suffixes
# (B4, B16, …) get spelled out: B -> "BFour", "BOneSix", …
_DIGIT_WORDS = {
    "0": "Zero", "1": "One", "2": "Two", "3": "Three", "4": "Four",
    "5": "Five", "6": "Six", "7": "Seven", "8": "Eight", "9": "Nine",
}


def bpb_suffix(bpb: int) -> str:
    return "B" + "".join(_DIGIT_WORDS[d] for d in str(bpb))


# Greek -> Latin transliteration for filenames. Decomposes accents via
# NFKD, drops combining marks, then maps Greek letters to Latin
# equivalents (modern phonetic transliteration: β -> v, η -> i, etc.).
GREEK_TO_LATIN = {
    "α": "a", "β": "v", "γ": "g", "δ": "d", "ε": "e", "ζ": "z",
    "η": "i", "θ": "th", "ι": "i", "κ": "k", "λ": "l", "μ": "m",
    "ν": "n", "ξ": "x", "ο": "o", "π": "p", "ρ": "r", "σ": "s",
    "ς": "s", "τ": "t", "υ": "y", "φ": "f", "χ": "ch", "ψ": "ps",
    "ω": "o",
    "Α": "A", "Β": "V", "Γ": "G", "Δ": "D", "Ε": "E", "Ζ": "Z",
    "Η": "I", "Θ": "Th", "Ι": "I", "Κ": "K", "Λ": "L", "Μ": "M",
    "Ν": "N", "Ξ": "X", "Ο": "O", "Π": "P", "Ρ": "R", "Σ": "S",
    "Τ": "T", "Υ": "Y", "Φ": "F", "Χ": "Ch", "Ψ": "Ps", "Ω": "O",
}


# ─── glyph rendering ──────────────────────────────────────────────────────

def latin_glyph(cell):
    if cell is None:
        return " "
    g, a = cell["glyph"], cell["accent"]
    if g == "dum": return "D"
    if g == "tek": return "T" if a else "t"
    if g == "ka":  return "K" if a else "k"
    if g == "slap": return "S"
    return " "


def greek_glyph(cell):
    if cell is None:
        return " "
    g, a = cell["glyph"], cell["accent"]
    if g == "dum": return ">"
    if g == "tek": return "Δ" if a else "δ"
    if g == "ka":  return "Α" if a else "α"
    if g == "slap": return "S"
    return " "


def slugify(title: str) -> str:
    """Latin-only slug. Greek letters are transliterated; combining
    marks (accents) are stripped via NFKD; anything else non-ASCII is
    dropped."""
    s = unicodedata.normalize("NFKD", title)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = "".join(GREEK_TO_LATIN.get(c, c) for c in s)
    s = s.lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"[\s_-]+", "-", s).strip("-")
    return s or "rhythm-pdf"


# ─── parsing ──────────────────────────────────────────────────────────────

def extract_durations(rhythm_str: str):
    """Return the set of integer durations used in a rhythm string,
    resolving sticky-duration tokens against the previous duration.

    A dotted duration `Nd.` contributes `2*N` to the set so the LCM-based
    BPB autocalc reserves a fine-enough grid for `3*N/2`-length tokens
    to land on integer cell boundaries.
    """
    durations = []
    prev = "4"
    for raw in rhythm_str.replace("|", " ").split():
        m = _TOKEN_RE.match(raw)
        if not m:
            continue
        d = m.group(2)
        if d is None:
            d = prev
        prev = d
        if d.endswith("."):
            durations.append(2 * int(d[:-1]))
        else:
            durations.append(int(d))
    return set(durations)


def auto_bpb(rhythm_node: dict, meter: str) -> int:
    """Auto-calculate boxes-per-beat from the LCM of durations used across
    ALL variations of this rhythm, divided by the meter's denominator.

    For 9/8 with smallest=16: LCM(4,8,16)=16 -> BPB = 16/8 = 2.
    For 9/4 with smallest=8:  LCM(4,8)  = 8  -> BPB = 8/4  = 2.
    Falls back to 4 if no durations can be extracted.
    """
    from math import lcm
    meter_den = int(meter.split("/")[1])
    all_d = set()
    for var in rhythm_node.get("variations", {}).values():
        rhythm_str = var.get("rhythm") if isinstance(var, dict) else None
        if rhythm_str:
            all_d.update(extract_durations(rhythm_str))
    if not all_d:
        return 4
    lcm_val = 1
    for d in all_d:
        lcm_val = lcm(lcm_val, d)
    bpb = max(1, lcm_val // meter_den)
    return bpb


def cells_for_duration(dur: str, bpb: int, meter_den: int) -> int:
    """How many TUBS cells a token of duration `dur` occupies.
    `dur` is a string: bare base ('4', '8', '16') or dotted ('8.', '4.').
    """
    num = meter_den * bpb
    if dur.endswith("."):
        base = int(dur[:-1])
        # dotted = 3/(2*base) of a whole note → 3*num/(2*base) cells
        if (3 * num) % (2 * base) != 0:
            raise ValueError(
                f"dotted duration {dur} does not fit cleanly in "
                f"{bpb}-per-beat grid with denominator {meter_den}"
            )
        return (3 * num) // (2 * base)
    d = int(dur)
    if num % d != 0:
        raise ValueError(
            f"duration {dur} does not fit cleanly in {bpb}-per-beat grid "
            f"with denominator {meter_den}"
        )
    return num // d


REPEAT_BAR = "%"   # a whole-bar token meaning "repeat the previous bar".
                   # Its drummode is the sentinel [REPEAT_BAR] and its cells
                   # are None: a compact one-beat-wide measure-repeat sign,
                   # NOT a re-notated bar (see render_staff / render_tubs).

# Hand-drawn measure-repeat sign: a thick slash with a dot in the upper
# and lower triangle. LilyPond's `repeats.*` feta glyphs aren't reachable
# via \musicglyph, and drawing it ourselves lets us size it small enough
# to fit a compact (one-beat-wide) repeat cell.
PERCENT_SIGN = (
    r"\override #'(thickness . 2.0) \combine \draw-line #'(0.95 . 1.5) "
    r"\combine \translate #'(0.05 . 1.2) \draw-circle #0.18 #0.0 ##t "
    r"\translate #'(0.86 . 0.28) \draw-circle #0.18 #0.0 ##t"
)


def parse_rhythm(rhythm_str: str, bpb: int, meter_den: int):
    bars = []
    prev_duration = "4"
    for bar_str in rhythm_str.split("|"):
        bar_str = bar_str.strip()
        if not bar_str:
            continue
        if bar_str == REPEAT_BAR:
            if not bars:
                raise ValueError("'%' repeat bar has no preceding bar")
            # Sentinel drummode + None cells: render_staff/render_tubs draw
            # a compact one-beat-wide percent sign, not a re-notated bar.
            bars.append(([REPEAT_BAR], None))
            continue
        drummode = []
        cells = []
        for raw in bar_str.split():
            m = _TOKEN_RE.match(raw)
            if not m:
                raise ValueError(f"cannot parse token {raw!r}")
            head_raw, duration, accent, beam = m.group(1), m.group(2), m.group(3), m.group(4)
            middle = head_raw.startswith("(") and head_raw.endswith(")")
            head = head_raw[1:-1] if middle else head_raw
            if middle and HEAD_TO_DRUM.get(head) != "ka":
                raise ValueError(
                    f"middle-finger marker (...) only applies to kah, got {raw!r}"
                )
            if duration is None:
                duration = prev_duration
            prev_duration = duration
            drum = HEAD_TO_DRUM[head]

            if drum is None:    # rest
                tok = f"r{duration}"
            elif drum == "dum":
                tok = f"dum{duration}_>"
            else:
                below = HEAD_TO_BELOW[head]
                if middle:
                    tok = (
                        f"{drum}{duration}"
                        f"_\\markup {{ \\override #'(thickness . 1.6) "
                        f"\\override #'(circle-padding . 0.35) "
                        f"\\circle \"{below}\" }}"
                    )
                else:
                    tok = f"{drum}{duration}_{below}"
                if accent:
                    tok += "^>"
            if beam:
                tok += beam   # LilyPond manual-beam markers: `[` open, `]` close
            drummode.append(tok)

            n = cells_for_duration(duration, bpb, meter_den)
            if drum is None:
                cells.extend([None] * n)
            else:
                cells.append({"glyph": drum, "accent": bool(accent), "middle": middle})
                cells.extend([None] * (n - 1))
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


# ─── geometry ─────────────────────────────────────────────────────────────

def cell_geometry(bpb: int, layout: dict = DEFAULT_LAYOUT):
    cell_size = REFERENCE_CELL_SIZE * REFERENCE_BPB / bpb * layout["cell_scale"]
    half = cell_size / 2.0
    font_offset = round(2 * math.log2(cell_size / REFERENCE_CELL_SIZE))
    tubs_font = REFERENCE_TUBS_FONT + font_offset + layout["tubs_font_offset"]
    count_font = REFERENCE_COUNT_FONT + font_offset + layout["count_font_offset"]
    scale = cell_size / REFERENCE_CELL_SIZE
    divider = REFERENCE_DIVIDER * scale
    outer = REFERENCE_OUTER * scale
    divider_thick = divider * DIVIDER_THICK_RATIO
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


# ─── LilyPond templating ──────────────────────────────────────────────────

PREAMBLE = r"""\version "2.24.0"

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

% Teacher 2-line staff: dum + slap share the lower line; tek + ka share
% the upper line. The Greek letter markup under each note still tells the
% reader which stroke it is. Lines themselves are rendered transparent
% in render_staff for teacher mode (StaffSymbol.transparent = ##t), so
% only the noteheads + beams + Greek labels remain on the page.
% Positions ±1 keep dum/slap and tek/ka close enough that beam groups
% read as one rhythm but distinct enough to be readable.
#(define darbuka-style-teacher '(
  (dum default #f -1)
  (slap cross #f -1)
  (tek default #f 1)
  (ka default #f 1)
))

drumPitchNames.dum = #'dum
drumPitchNames.tek = #'tek
drumPitchNames.ka = #'ka
drumPitchNames.slap = #'slap

\paper {
  top-margin = 40
  bottom-margin = 30
  left-margin = 25
  right-margin = 25
  % force every single-bar system to fill the line width so the
  % proportional spacing inside is consistent across variations
  ragged-right = ##f
  ragged-last = ##f
  % keep content anchored near the top of each page instead of being
  % vertically stretched/centered when it doesn't fill the page
  ragged-bottom = ##t
  ragged-last-bottom = ##t
  % tighter vertical spacing between music staff and the TUBS markup below
  score-markup-spacing.basic-distance = #4
  score-markup-spacing.minimum-distance = #2
  score-markup-spacing.padding = #0.5
  % tighter spacing between adjacent markups (TUBS row + next-variation start)
  markup-markup-spacing.basic-distance = #2
  markup-markup-spacing.padding = #0.5
  markup-system-spacing.basic-distance = #4
  markup-system-spacing.padding = #0.5
  % extra space between the PDF title and the first rhythm
  top-markup-spacing.basic-distance = #14
  top-markup-spacing.padding = #4
  % Title should print only on the TOC (book's first page). LilyPond
  % otherwise prints the book/score title at the top of every bookpart's
  % first page. Blank both markups; the title is emitted explicitly as
  % markup before the TOC in book_body (see main()).
  bookTitleMarkup = \markup { }
  scoreTitleMarkup = \markup { }
}

\layout {
  \context {
    \Score
    % uniform-stretching makes note spacing strictly proportional to
    % duration, so the same time-position in every variation lands at the
    % same X coordinate across the page — i.e. the second dum (or any
    % other beat) lines up vertically across the stack of variations.
    \override SpacingSpanner.uniform-stretching = ##t
    \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/4)
    \override SpacingSpanner.strict-note-spacing = ##t
    \override SpacingSpanner.spacing-increment = #3.0
    \override SpacingSpanner.shortest-duration-space = #1.5
    \override MetronomeMark.padding = #8
    \override RehearsalMark.extra-offset = #'(0 . 8)
    % Thin beat & half-beat bar lines
    \override BarLine.hair-thickness = #0.6
    \override BarLine.thick-thickness = #1.2
  }
  \context {
    \Staff
    \override StaffSymbol.staff-space = __STAFF_SPACE__
  }
}
"""


def cell_command_block(bpb: int, geom: dict) -> str:
    """Return LilyPond markup-command definitions for a specific BPB.

    Functions are suffixed with B<bpb> so a bundle can mix several
    different boxes-per-beat settings in the same file.
    """
    g = {
        "BPB": bpb_suffix(bpb),
        "CELL_SIZE": f"{geom['cell_size']:.4f}",
        "NEG_HALF": f"{-geom['half']:.4f}",
        "POS_HALF": f"{geom['half']:.4f}",
        "TUBS_FONT": str(geom["tubs_font"]),
        "COUNT_FONT": str(geom["count_font"]),
        "DIVIDER": f"{geom['divider']:.3f}",
        "DIVIDER_THICK": f"{geom['divider_thick']:.3f}",
        "TUBS_TEXT_Y": f"{geom['tubs_text_y']:.4f}",
        "COUNT_NEG_Y": f"{geom['count_neg_y']:.4f}",
        "COUNT_POS_Y": f"{geom['count_pos_y']:.4f}",
        "COUNT_CELL_H": f"{geom['count_cell_h']:.4f}",
        "COUNT_TEXT_Y": f"{geom['count_text_y']:.4f}",
    }
    tpl = r"""
% --- TUBS markup commands for boxes_per_beat = __BPB__ ---
#(define-markup-command (tubsCell__BPB__ layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

#(define-markup-command (tubsCellThick__BPB__ layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER_THICK__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

#(define-markup-command (tubsCellCircle__BPB__ layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

#(define-markup-command (tubsCellCircleThick__BPB__ layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__NEG_HALF__ . __POS_HALF__)
             \translate #'(0 . __TUBS_TEXT_Y__)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #__TUBS_FONT__ #text
           \translate #'(__POS_HALF__ . __NEG_HALF__)
             \override #'(thickness . __DIVIDER_THICK__)
             \draw-line #'(0 . __CELL_SIZE__)
         }
       } #}))

#(define-markup-command (countCell__BPB__ layout props label)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(__NEG_HALF__ . __POS_HALF__) #'(__COUNT_NEG_Y__ . __COUNT_POS_Y__)
             \translate #'(0 . __COUNT_TEXT_Y__)
             \halign #CENTER \fontsize #__COUNT_FONT__ #label
           \translate #'(__POS_HALF__ . __COUNT_NEG_Y__)
             \transparent
             \override #'(thickness . __DIVIDER__)
             \draw-line #'(0 . __COUNT_CELL_H__)
         }
       } #}))
"""
    out = tpl
    for k, v in g.items():
        out = out.replace(f"__{k}__", v)
    return out


def render_tubs_row(cells, glyph_func, bpb, cmd_suffix):
    parts = []
    for i, c in enumerate(cells):
        glyph = glyph_func(c)
        is_beat_end = (i + 1) % bpb == 0
        circled = bool(c and c.get("middle"))
        # The final cell of the bar is always a beat end (bar length is a
        # multiple of bpb): give it the thick divider too so the bar-end
        # line is the heaviest, matching the staff's thick \bar ".".
        thick = is_beat_end
        if circled:
            base = "tubsCellCircleThick" if thick else "tubsCellCircle"
        else:
            base = "tubsCellThick" if thick else "tubsCell"
        parts.append(f'\\{base}{cmd_suffix} "{glyph}"')
    return " ".join(parts)


def render_count_row(labels, cmd_suffix):
    return " ".join(f'\\countCell{cmd_suffix} "{c}"' for c in labels)


def _variation_label(var_id: str) -> str:
    m = re.match(r"^v(\d+)$", var_id)
    return m.group(1) if m else var_id


def _tick_pattern_one_bar(meter_den: int, meter_num: int, bpb: int,
                          no_interior_bars: bool = False,
                          no_end_bar: bool = False) -> str:
    """Spacer-voice pattern: one bar mark per TUBS cell.

    Thick bar (`\\bar "."`) ends the bar — the heaviest line, so bar
    boundaries stand out. Solid bar (`\\bar "|"`) lands at every interior
    beat boundary — the same positions where the TUBS row draws a thick
    divider (every BPB-th cell). Dashed bar (`\\bar "!"`) lands at every
    intermediate cell boundary — a thin divider between cells.

    Spacers (`s<dur>`) don't render notes, so the marks fire at every
    cell boundary regardless of where the music voice's notes start or
    end.

    `no_interior_bars`: drop both the dashed sub-beat marks AND the
    medium beat marks, leaving only the thick end-of-bar line. The
    notehead style already conveys duration, so on the teacher PDF
    every interior division is noise.

    `no_end_bar`: also drop the end-of-bar mark. Use this for the
    final bar of a variation when nothing follows it — the variation
    just dissolves into whitespace.
    """
    cell_dur = bpb * meter_den          # LilyPond duration for one cell
    n_ticks = bpb * meter_num           # total cell boundaries per bar
    parts = []
    for i in range(1, n_ticks + 1):
        parts.append(f"s{cell_dur}")
        if i == n_ticks:
            bar = '' if no_end_bar else '\\bar "."'   # thick end-of-bar
        elif no_interior_bars:
            bar = ''                    # drop all interior divisions
        elif i % bpb == 0:
            bar = '\\bar "|"'           # interior beat boundary
        else:
            bar = '\\bar "!"'           # sub-beat cell boundary
        if bar:
            parts.append(bar)
        # Every \bar is otherwise a candidate line-break; suppress except
        # at the final bar of the user-bar (so multi-bar variations can
        # still wrap between bars).
        if i < n_ticks:
            parts.append("\\noBreak")
    return " ".join(parts)


def render_staff(slug: str, var_id: str, var: dict, show_label: bool = True,
                 no_interior_bars: bool = False, teacher_staff: bool = False) -> str:
    """Return the `\\new DrumStaff` expression (not wrapped in \\score).

    Two parallel voices inside the DrumStaff:
      1. `\\drummode` — the actual rhythm (notes, beams, accents).
      2. A spacer-only voice that emits a thin bar mark at every half-
         beat and full-beat. Spacers (`s`) don't render so the marks
         can land at any time-position, including mid-note positions
         the drum voice itself can't accommodate.
    Both voices share the Score's SpacingSpanner so the bars align
    precisely under their time-positions.
    """
    meter = var["meter"]
    bpb = int(var.get("boxes_per_beat", DEFAULT_BPB))
    meter_num, meter_den = (int(x) for x in meter.split("/"))
    bars = parse_rhythm(var["rhythm"], bpb, meter_den)
    tick_per_bar = _tick_pattern_one_bar(meter_den, meter_num, bpb,
                                         no_interior_bars=no_interior_bars)
    # Teacher mode: the very last bar of the variation drops its
    # end-of-bar so the staff just trails off. Other bars (interior
    # bar boundaries within multi-bar variations) keep their thick bar.
    tick_per_last_bar = _tick_pattern_one_bar(
        meter_den, meter_num, bpb,
        no_interior_bars=no_interior_bars,
        no_end_bar=teacher_staff,
    )
    # A `%` bar renders as a compact one-beat-wide measure-repeat sign: a
    # transparent (still space-occupying) rest of one beat carrying the
    # hand-drawn percent markup, with a matching one-beat spacer + closing
    # bar in the tick voice so the two parallel voices stay duration-synced
    # and the sign lands narrow instead of full-bar-wide.
    beat = meter_den
    pct_music = (
        f"\\once \\override Rest.transparent = ##t r{beat} "
        f"^\\markup {{ \\halign #CENTER \\translate #'(0 . -2.0) "
        f"{{ {PERCENT_SIGN} }} }}"
    )
    pct_tick = f's{beat} \\bar "."'   # thick line ends the repeat bar too
    # Default: keep all bars of a variation on one system. A YAML may set
    # `single_line: false` to opt into a system break per bar (useful for
    # very long rhythms where compression would hurt readability).
    single_line = bool(var.get("single_line", True))

    # All bars share one system by default (single_line resolves to True);
    # an opt-in `single_line: false` would emit a `\break` per real bar.
    # Compact `%` repeats always stay glued to the bar they repeat (never
    # a break before them).
    music_pieces, tick_pieces = [], []
    for idx, (drum, _cells) in enumerate(bars):
        is_repeat = drum == [REPEAT_BAR]
        is_last = (idx == len(bars) - 1)
        if idx > 0:
            music_pieces.append(
                " " if (single_line or is_repeat) else " \\break "
            )
        if is_repeat:
            music_pieces.append(pct_music)
            tick_pieces.append(pct_tick)
        else:
            music_pieces.append(" ".join(drum))
            tick_pieces.append(tick_per_last_bar if is_last else tick_per_bar)
    drummode_body = "".join(music_pieces)
    tick_voice = " ".join(tick_pieces)

    var_label = _variation_label(var_id) if show_label else ""
    line_count = 2 if teacher_staff else 3
    style_table = "darbuka-style-teacher" if teacher_staff else "darbuka-style"
    # Teacher staff: positions ±1 keep dum/slap and tek/ka close;
    # StaffSymbol.stencil = ##f hides the lines themselves AND removes
    # their X extent at the start of the staff. Clef.stencil = ##f
    # removes the percussion clef (the "II" glyph DrumStaff draws by
    # default). TextScript overrides park the Greek letter labels at a
    # consistent Y position below the noteheads.
    extra_overrides = "" if not teacher_staff else (
        "\n      \\override StaffSymbol.line-positions = #'(-1 1)"
        "\n      \\override StaffSymbol.stencil = ##f"
        "\n      \\override Clef.stencil = ##f"
        "\n      \\override TextScript.staff-padding = #2.5"
        "\n      \\override TextScript.outside-staff-priority = ##f"
        "\n      \\override TextScript.self-alignment-X = #CENTER"
    )

    return f"""    \\new DrumStaff \\with {{
      \\override StaffSymbol.line-count = #{line_count}
      drumStyleTable = #(alist->hash-table {style_table})
      instrumentName = "{var_label}"{extra_overrides}
    }}
    <<
      \\drummode {{
        \\cadenzaOn   % manual bar-line control via the tick voice below
        \\time {meter}
        \\stemUp
        \\autoBeamOff
        \\override Beam.damping = #0
        \\override Beam.auto-knee-gap = #10000
        \\override Beam.positions = #'(4 . 4)
        {drummode_body}
      }}
      {{ {tick_voice} }}
    >>"""


def render_blank_staff(meter: str, bpb: int, bars_count: int = 1, label: str = "",
                       no_interior_bars: bool = False, teacher_staff: bool = False) -> str:
    """Empty drum staff for the teacher PDF: `bars_count` bars at the
    given meter with all rests rendered transparent. The bar-line tick
    voice still fires, so the staff shows the meter signature, the
    interior beat divisions, and a thick end-of-bar — a blank canvas
    the teacher can write on (e.g. on a Remarkable). bars_count
    typically matches the rhythm's existing variations so the teacher
    gets the same amount of writing space per blank line. The extra
    `staff-staff-spacing.basic-distance` opens vertical room above the
    blank line so a hand-written tall notehead doesn't crash into the
    staff above."""
    meter_num, meter_den = (int(x) for x in meter.split("/"))
    bar_rests = " ".join([f"r{meter_den}"] * meter_num)
    tick_per_bar = _tick_pattern_one_bar(meter_den, meter_num, bpb,
                                         no_interior_bars=no_interior_bars)
    tick_per_last_bar = _tick_pattern_one_bar(
        meter_den, meter_num, bpb,
        no_interior_bars=no_interior_bars,
        no_end_bar=teacher_staff,
    )
    # Repeat bar_rests bars_count times, with the last bar's tick
    # dropping its end-of-bar in teacher mode.
    rests_body = " ".join([bar_rests] * bars_count)
    ticks_list = [tick_per_bar] * max(0, bars_count - 1) + [tick_per_last_bar]
    tick_voice = " ".join(ticks_list)
    line_count = 2 if teacher_staff else 3
    style_table = "darbuka-style-teacher" if teacher_staff else "darbuka-style"
    extra_overrides = "" if not teacher_staff else (
        "\n      \\override StaffSymbol.line-positions = #'(-1 1)"
        "\n      \\override StaffSymbol.stencil = ##f"
        "\n      \\override Clef.stencil = ##f"
    )
    return f"""    \\new DrumStaff \\with {{
      \\override StaffSymbol.line-count = #{line_count}
      drumStyleTable = #(alist->hash-table {style_table})
      instrumentName = "{label}"
      \\override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \\override VerticalAxisGroup.staff-staff-spacing.padding = #2{extra_overrides}
    }}
    <<
      \\drummode {{
        \\cadenzaOn
        \\time {meter}
        \\stemUp
        \\autoBeamOff
        \\override Rest.transparent = ##t
        {rests_body}
      }}
      {{ {tick_voice} }}
    >>"""


def render_blank_canvas(label: str = "", teacher_staff: bool = False) -> str:
    """One blank drum staff with no time signature and no internal
    bar lines — a pure writing canvas for inventing new rhythms. The
    teacher's final-page set of 10 of these is the place to draft."""
    line_count = 2 if teacher_staff else 3
    style_table = "darbuka-style-teacher" if teacher_staff else "darbuka-style"
    extra_overrides = "" if not teacher_staff else (
        "\n      \\override StaffSymbol.line-positions = #'(-1 1)"
        "\n      \\override StaffSymbol.stencil = ##f"
        "\n      \\override Clef.stencil = ##f"
    )
    return f"""    \\new DrumStaff \\with {{
      \\override StaffSymbol.line-count = #{line_count}
      drumStyleTable = #(alist->hash-table {style_table})
      instrumentName = "{label}"
      \\override Staff.TimeSignature.transparent = ##t
      \\override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \\override VerticalAxisGroup.staff-staff-spacing.padding = #3{extra_overrides}
    }}
    <<
      \\drummode {{
        \\cadenzaOn
        \\stemUp
        \\autoBeamOff
        \\override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \\bar "."
      }}
    >>"""


def render_tubs(slug: str, var_id: str, var: dict, geom: dict, show_label: bool = True) -> str:
    """Return the TUBS \\column for one variation (Greek row + Latin row +
    counts, repeated per bar)."""
    meter = var["meter"]
    bpb = int(var.get("boxes_per_beat", DEFAULT_BPB))
    meter_num, meter_den = (int(x) for x in meter.split("/"))
    bars = parse_rhythm(var["rhythm"], bpb, meter_den)
    counts = count_row(meter, bpb)
    expected_cells = meter_num * bpb
    cmd_suffix = bpb_suffix(bpb)
    var_label = _variation_label(var_id) if show_label else ""
    label_markup = (
        f'\\hspace #2 \\raise #1 {{ \\bold "{var_label}" }} \\hspace #2\n      '
        if show_label else ""
    )

    bar_inners = []
    for i, (_drum, cells) in enumerate(bars):
        if cells is None:   # compact `%` repeat: a single small percent box
            bar_inners.append(
                "      \\center-column {\n"
                f"        {{ \\override #'(box-padding . 0.5)"
                f" \\override #'(thickness . {geom['outer']:.3f})"
                f" \\box {{ {PERCENT_SIGN} }} }}\n"
                "      }"
            )
            continue
        if len(cells) != expected_cells:
            sys.stderr.write(
                f"warning: {slug}-{var_id} bar {i+1}: cells {len(cells)} "
                f"!= expected {expected_cells}\n"
            )
        inner = (
            "      \\center-column {\n"
            f"        {{ \\override #'(box-padding . 0) \\override #'(thickness . {geom['outer']:.3f})"
            f" \\box \\concat {{ {render_tubs_row(cells, greek_glyph, bpb, cmd_suffix)} }} }}\n"
            f"        {{ \\override #'(box-padding . 0) \\override #'(thickness . {geom['outer']:.3f})"
            f" \\box \\concat {{ {render_tubs_row(cells, latin_glyph, bpb, cmd_suffix)} }} }}\n"
            f"        \\concat {{ {render_count_row(counts, cmd_suffix)} }}\n"
            "      }"
        )
        bar_inners.append(inner)

    if var.get("single_line", True):
        # All bars share one label, laid out horizontally with a small gap.
        joined = "\n      \\hspace #1\n".join(bar_inners)
        return (
            "    \\concat {\n"
            f"      {label_markup}"
            f"{joined}\n"
            "    }"
        )

    tubs_blocks = [
        (
            "    \\concat {\n"
            f"      {label_markup}"
            f"{inner}\n"
            "    }"
        )
        for inner in bar_inners
    ]
    separator = f"\n    \\vspace #{BAR_VSPACE}\n"
    return separator.join(tubs_blocks)


# ─── orchestration ────────────────────────────────────────────────────────

def parse_spec(spec: str):
    if "-" not in spec:
        raise ValueError(f"bad spec {spec!r}: expected <slug>-<variation>")
    slug, var_id = spec.rsplit("-", 1)
    return slug, var_id


def parse_set_file(path: Path):
    """Read a rhythm *set* file: a plain-text playlist of rhythms that
    only references entries already in `rhythms.yaml`.

    Format (one directive/spec per line, order preserved):
      - `# ...`          comment, ignored
      - blank line       ignored
      - `title: <text>`  optional PDF-title override
      - `<slug> <var>`   a rhythm spec, whitespace- or hyphen-separated
                         (e.g. `sofyan v1`, `kasik_havasi v2`, `sofyan-v1`)

    Returns (title_or_None, [spec, ...]) with specs normalized to the
    `<slug>-<variation>` form the rest of the pipeline expects.
    """
    title = None
    specs = []
    for lineno, raw in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.lower().startswith("title:"):
            title = line.split(":", 1)[1].strip() or None
            continue
        parts = line.replace("-", " ").split()
        if len(parts) != 2:
            sys.exit(
                f"{path.name}:{lineno}: bad spec {raw.strip()!r}: expected "
                f"`<slug> <variation>` (e.g. `sofyan v1`)"
            )
        specs.append(f"{parts[0]}-{parts[1]}")
    if not specs:
        sys.exit(f"{path.name}: no rhythm specs found")
    return title, specs


# (load_db() is defined above and walks rhythms/*.yaml directly.)


def compile_ly(path: Path) -> bool:
    if not shutil.which("lilypond"):
        sys.stderr.write("lilypond not on PATH; skipping compile\n")
        return False
    try:
        r = subprocess.run(
            ["lilypond", path.name],
            cwd=path.parent,
            capture_output=True,
            text=True,
            timeout=180,
            errors="replace",
        )
    except subprocess.TimeoutExpired:
        sys.stderr.write(f"lilypond timed out compiling {path.name}\n")
        return False
    if r.returncode != 0:
        tail = (r.stderr or r.stdout).strip().splitlines()[-8:]
        sys.stderr.write("lilypond failed:\n  " + "\n  ".join(tail) + "\n")
        return False
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--title", help="PDF title (overrides a set-file title:)")
    ap.add_argument("specs", nargs="*", help="rhythm specs (slug-vN)")
    ap.add_argument("--set", dest="set_file",
                    help="read specs (and optional title:) from a set file")
    ap.add_argument("--no-compile", action="store_true",
                    help="write .ly but skip LilyPond compile")
    ap.add_argument("--no-open", action="store_true",
                    help="skip `open` after a successful compile")
    ap.add_argument("--variant", choices=sorted(LAYOUT_PRESETS),
                    help="layout preset: bigger pentagram and smaller boxes")
    ap.add_argument("--no-tubs", action="store_true",
                    help="omit the TUBS box rows (staff-only PDF)")
    ap.add_argument("--blank-extras", type=int, default=0, metavar="N",
                    help="append N blank pentagrams per rhythm (for a teacher "
                         "PDF the student can fill in by hand)")
    ap.add_argument("--new-rhythm-blanks", type=int, default=0, metavar="N",
                    help="append a final page with N totally blank pentagrams "
                         "(no time signature, no bar lines) for new rhythms")
    ap.add_argument("--ragged", action="store_true",
                    help="ragged-right + no inter-variation note alignment — "
                         "each staff takes only as much width as it needs")
    ap.add_argument("--no-interior-bars", dest="no_interior_bars",
                    action="store_true",
                    help="hide every interior bar line inside a measure (both "
                         "beat and sub-beat divisions). Only the end-of-bar "
                         "thick line remains; notehead style still conveys "
                         "duration on its own.")
    ap.add_argument("--teacher-staff", dest="teacher_staff",
                    action="store_true",
                    help="2-line staff: dum + slap on the lower line, "
                         "tek + ka on the upper line. Greek letter labels "
                         "still distinguish each stroke.")
    args = ap.parse_args()

    layout = LAYOUT_PRESETS[args.variant] if args.variant else DEFAULT_LAYOUT

    title = args.title
    specs = list(args.specs)
    if args.set_file:
        set_path = Path(args.set_file).expanduser()
        if not set_path.is_absolute():
            set_path = (Path.cwd() / set_path).resolve()
        if not set_path.exists():
            sys.exit(f"set file not found: {set_path}")
        file_title, file_specs = parse_set_file(set_path)
        specs = file_specs + specs   # set-file specs first, CLI specs appended
        if title is None:
            title = file_title or (
                set_path.stem.replace("_", " ").replace("-", " ").title()
            )
    if not specs:
        sys.exit("no specs given (pass them on the CLI or via --set FILE)")
    if title is None:
        sys.exit("--title is required when not using --set")

    db = load_db()

    sections = []
    seen_bpb = set()
    for spec in specs:
        slug, var_id = parse_spec(spec)
        if slug not in db:
            sys.exit(
                f"unknown rhythm {slug!r}. available: {', '.join(sorted(db))}"
            )
        rhythm = db[slug]
        variations = rhythm.get("variations", {})
        if var_id not in variations:
            sys.exit(
                f"unknown variation {var_id!r} for {slug!r}. "
                f"available: {', '.join(sorted(variations))}"
            )
        var = variations[var_id]
        # Meter is rhythm-level by default; per-variation override allowed.
        meter = var.get("meter") or rhythm.get("meter")
        if not meter:
            sys.exit(
                f"no meter for {slug}-{var_id} "
                f"(set it at the rhythm level in rhythms.yaml)"
            )
        # BPB: variation override > rhythm-level override > auto-calc from
        # LCM of durations across all variations of this rhythm.
        if var.get("boxes_per_beat") is not None:
            bpb = int(var["boxes_per_beat"])
        elif rhythm.get("boxes_per_beat") is not None:
            bpb = int(rhythm["boxes_per_beat"])
        else:
            bpb = auto_bpb(rhythm, meter)
        var = {**var, "meter": meter, "boxes_per_beat": bpb}
        seen_bpb.add(bpb)
        sections.append((slug, var_id, rhythm.get("display", slug), var, bpb))

    # Emit markup-command definitions once per unique BPB so bundles can
    # mix different grids cleanly.
    cmd_blocks = []
    for bpb in sorted(seen_bpb):
        geom = cell_geometry(bpb, layout)
        cmd_blocks.append(cell_command_block(bpb, geom))

    # Group sections by rhythm slug (preserve user-given order). All
    # variations of one rhythm share a single \score so their beats align
    # via shared SpacingSpanner. Different rhythms become separate
    # (score + TUBS) groups so each rhythm's TUBS sits directly under
    # its pentagram.
    groups = []   # list of (slug, [section, ...])
    for s in sections:
        slug = s[0]
        if groups and groups[-1][0] == slug:
            groups[-1][1].append(s)
        else:
            groups.append((slug, [s]))

    tubs_inner_separator = f"\n    \\vspace #{SECTION_VSPACE}\n"

    # Prefix every rhythm group with its display name as a subheading,
    # under the global PDF title. With multiple groups this tells the
    # reader which pentagram is which; with a single group it still names
    # the rhythm distinctly from the (possibly different) PDF title.
    show_headings = True

    group_blocks = []   # [(display, content), ...]
    for slug, group_sections in groups:
        total_variations = len(group_sections) + args.blank_extras
        # Variation labels (the bold "1", "2", ...) make sense as soon as
        # we have more than one staff in the group — either real variations
        # or teacher blanks.
        show_var_label = total_variations > 1
        staves = []
        tubs_columns = []
        for _, var_id, display, var, bpb in group_sections:
            geom = cell_geometry(bpb, layout)
            staves.append(render_staff(slug, var_id, var, show_label=show_var_label,
                                         no_interior_bars=args.no_interior_bars,
                                         teacher_staff=args.teacher_staff))
            tubs_columns.append(
                render_tubs(slug, var_id, var, geom, show_label=show_var_label)
            )
        # Append N empty pentagrams for the teacher to fill in by hand.
        # They share the meter + bpb + bar count of the last real
        # variation, so a 2-bar rhythm gets 2 empty bars of writing
        # space per blank line. Labels continue past the existing
        # variations (e.g. v1, v2 → blanks 3, 4, 5, ...).
        if args.blank_extras > 0:
            last_var = group_sections[-1][3]
            meter, bpb = last_var["meter"], last_var["boxes_per_beat"]
            # Bar count = parse_rhythm bars, including any `%` repeat bars.
            last_bars = parse_rhythm(last_var["rhythm"], bpb,
                                     int(meter.split("/")[1]))
            bars_count = max(1, len(last_bars))
            next_n = len(group_sections) + 1
            for i in range(args.blank_extras):
                label = str(next_n + i) if show_var_label else ""
                staves.append(render_blank_staff(meter, bpb,
                                                  bars_count=bars_count,
                                                  label=label,
                                                  no_interior_bars=args.no_interior_bars,
                                                  teacher_staff=args.teacher_staff))

        display = group_sections[0][2]
        heading_block = ""
        if show_headings:
            # Larger trailing vspace (#3 vs #0.5) opens a visible gap
            # between the rhythm title and its first variation.
            heading_block = (
                f'\n\\markup {{ \\vspace #0.5 \\bold \\fontsize #3 "{display}" }}\n'
                f'\\markup {{ \\vspace #3 }}\n'
            )

        if args.ragged:
            # Each variation is its own \score so its width matches its
            # own content. Parallel staves in a single \score would share
            # the system width, defeating the "as little width as needed"
            # goal — splitting them is the only way to get independent
            # widths.
            score_block = "".join(
                "\n\\score {\n  " + s.lstrip() + "\n}\n"
                for s in staves
            )
        else:
            score_block = (
                "\n\\score {\n"
                "  <<\n"
                + "\n".join(staves)
                + "\n  >>\n"
                "}\n"
            )
        tubs_block = "" if args.no_tubs else (
            "\n\\markup {\n  \\column {\n"
            + tubs_inner_separator.join(tubs_columns)
            + "\n  }\n}\n"
        )
        # TUBS row(s) sit directly below the music staves; LilyPond will
        # break to a new page only if they don't fit.
        group_blocks.append((display, heading_block + score_block + tubs_block))

    # One rhythm per page via \bookpart, with a clickable TOC at the top.
    # \tocItem inside each bookpart adds an entry that links to the start
    # of that bookpart's page in the produced PDF. \markuplist \table-of-
    # contents renders the TOC itself; \pageBreak forces the first rhythm
    # onto page 2.
    book_parts = []
    for display, content in group_blocks:
        safe = display.replace('"', '\\"')
        book_parts.append(
            "\\bookpart {\n"
            f"  \\tocItem \\markup \"{safe}\"\n"
            f"{content}"
            "}\n"
        )

    # Final "New Rhythms" page — totally blank pentagrams, no time signature
    # and no internal bar lines, for the teacher to draft brand-new rhythms.
    if args.new_rhythm_blanks > 0:
        canvas_staves = [render_blank_canvas(label=str(i + 1),
                                              teacher_staff=args.teacher_staff)
                         for i in range(args.new_rhythm_blanks)]
        if args.ragged:
            canvas_scores = "".join(
                "\n\\score {\n  " + s.lstrip() + "\n}\n"
                for s in canvas_staves
            )
        else:
            canvas_scores = (
                "\n\\score {\n  <<\n"
                + "\n".join(canvas_staves)
                + "\n  >>\n}\n"
            )
        book_parts.append(
            "\\bookpart {\n"
            "  \\tocItem \\markup \"New Rhythms\"\n"
            "\n\\markup { \\vspace #0.5 \\bold \\fontsize #3 \"New Rhythms\" }\n"
            f"{canvas_scores}"
            "}\n"
        )
    # Render the title once, on the TOC page, via an explicit \markup so
    # it doesn't repeat at the top of every bookpart (bookTitleMarkup is
    # blanked in the preamble).
    safe_title = title.replace('"', '\\"')
    book_body = (
        "\n\\book {\n"
        f'  \\markup {{ \\vspace #2 \\fill-line {{ \\fontsize #6 \\bold "{safe_title}" }} }}\n'
        "  \\markup { \\vspace #1 }\n"
        "  \\markuplist \\table-of-contents\n"
        "  \\pageBreak\n"
        + "".join(book_parts)
        + "}\n"
    )

    # `--ragged`: each staff system shrinks to the width its own notes
    # need, and uniform-stretching is disabled so variations no longer
    # pad to keep their notes column-aligned. The teacher PDF uses
    # this — every staff floats free of the others.
    ragged_overrides = "" if not args.ragged else r"""
\paper {
  ragged-right = ##t
  ragged-last = ##t
  indent = 8\mm
  % Each variation is its own \score in ragged mode; tighten the gap
  % between consecutive scores so they sit close together.
  % Roomy gap between scores so the Greek letter labels under each note
  % don't crash into the staff of the next variation, and so variations
  % feel like distinct lines rather than one tight column.
  score-system-spacing.basic-distance = #14
  score-system-spacing.minimum-distance = #10
  score-system-spacing.padding = #3
  system-system-spacing.basic-distance = #14
  system-system-spacing.padding = #3
}
\layout {
  \context {
    \Score
    \override SpacingSpanner.uniform-stretching = ##f
    \override SpacingSpanner.strict-note-spacing = ##f
    % Generous note-to-note spacing so the teacher edition reads as
    % spacious instead of crammed. shortest-duration-space sets the
    % minimum room each shortest note gets; spacing-increment scales
    % up from there for longer durations.
    \override SpacingSpanner.spacing-increment = #2.1
    \override SpacingSpanner.shortest-duration-space = #2.5
    \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/8)
    % Hide the system-start bracket at the left edge of every staff
    % (the two thin vertical lines LilyPond draws by default) — it's
    % redundant once the staff lines themselves are also transparent.
    \override SystemStartBar.transparent = ##t
    % Interior bar lines (between bars in multi-bar variations) get a
    % fixed vertical extent so the line is the same height for every
    % rhythm. The range -4 to 4 spans 8 staff-spaces — twice the
    % previous height — and stays centered at the staff midpoint.
    % minimum-X-extent forces breathing room on both sides so the bar
    % sits midway between the last note of bar 1 and the first note of
    % bar 2 instead of crowding either one.
    \override BarLine.bar-extent = #'(-8 . 8)
    \override BarLine.minimum-X-extent = #'(-4 . 4)
    \override BarLine.space-alist =
      #'((time-signature extra-space . 2.0)
         (custos minimum-space . 2.0)
         (clef minimum-space . 2.0)
         (key-signature extra-space . 1.0)
         (key-cancellation extra-space . 1.0)
         (first-note fixed-space . 4.0)
         (next-note semi-fixed-space . 4.0)
         (right-edge extra-space . 1.0))
  }
}
"""

    out = (
        PREAMBLE.replace("__TITLE__", title)
                .replace("__STAFF_SPACE__", f"{layout['staff_space']}")
        + ragged_overrides
        + "\n".join(cmd_blocks)
        + book_body
    )

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    filename = slugify(title)
    ly_path = OUT_DIR / f"{filename}.ly"
    ly_path.write_text(out, encoding="utf-8")
    print(f"wrote {ly_path.relative_to(REPO)}")

    if args.no_compile:
        return 0
    if not compile_ly(ly_path):
        return 1
    pdf_path = ly_path.with_suffix(".pdf")
    print(f"compiled {pdf_path.relative_to(REPO)}")
    if not args.no_open:
        subprocess.run(["open", str(pdf_path)], check=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
