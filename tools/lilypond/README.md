# LilyPond rhythm renderer

A pair of Python scripts that compile the YAML rhythm definitions in this repo into LilyPond `.ly` source files and then to print-quality PDF (drum staff + Greek TUBS row + Latin TUBS row + count row, all bar-aligned).

## Requirements

- Python ≥ 3.10
- PyYAML (`pip install pyyaml`)
- LilyPond on `$PATH` (macOS: `brew install lilypond`; Debian/Ubuntu: `apt install lilypond`; Windows: download from https://lilypond.org)

## Files

| File | What it does |
|---|---|
| `rhythm_to_ly.py` | Emits one `.ly` per variation under `../../bundles/` and compiles to PDF (unless `--no-compile`). Useful for a per-variation page. |
| `rhythm_pdf.py` | Bundles **multiple** rhythm-variations into one titled PDF, with a heading per spec. Used to build the full-library reference. |

## Generating the full-library PDF

From the repo root:

```bash
SPECS=$(python3 -c "
import yaml, glob
out = []
for f in sorted(glob.glob('rhythms/*.yaml')):
    d = yaml.safe_load(open(f))
    for slug, body in d.items():
        for v in (body.get('variations') or {}):
            out.append(f'{slug}-{v}')
print(' '.join(out))")

python3 tools/lilypond/rhythm_pdf.py \
    --title "Rythmiko Toxo — Full Library" \
    --no-open \
    $SPECS
```

Output lands at `bundles/rythmiko-toxo-full-library.{ly,pdf}`. Re-run after adding or editing a YAML file in `rhythms/` to refresh the bundled PDF.

## Generating a single variation

```bash
python3 tools/lilypond/rhythm_to_ly.py duyek-v2
```

Emits `bundles/duyek-v2.ly` and `bundles/duyek-v2.pdf` (pass `--no-compile` to skip the PDF).

## Rhythm-token grammar (reference)

See the top-level [`README.md`](../../README.md) for the full spec. Briefly:

- `>` (dum), `Δ` accented tek / `δ` unaccented, `Α` accented kah / `α` unaccented, `S` slap, `r` rest.
- Durations 4, 8, 16, 2, 1 (sticky — carries from previous token); `.` after = dotted.
- Beam group with `[` `]`. Bar separator `|`.
- `(Α)` (or `(ka)` / `(A)`) = middle-finger kah (rendered with a circled head in the TUBS).

The browser-based editor + validator at [bentenitis.com/rhythms](https://bentenitis.com/rhythms) parses the exact same grammar.
