#!/usr/bin/env python3
"""Render one rhythm YAML to a LilyPond PDF with tools/lilypond/rhythm_pdf.py.

    render_ly.py --yaml FILE --slug SLUG --out DIR [--style teacher|full]

rhythm_pdf.py reads every YAML in its RHYTHMS_DIR and writes to OUT_DIR,
both fixed to the repo. The editor keeps its data elsewhere, so this
wrapper points those two globals at a scratch folder that holds only the
rhythm being rendered, runs the converter's own main(), and renames the
result to DIR/<slug>.pdf (and .ly). Run as a subprocess by server.py so a
LilyPond hang or a converter sys.exit() never touches the server.
"""
import argparse
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "lilypond"))
import rhythm_pdf as rp  # noqa: E402
import yaml  # noqa: E402

# Same flags as the teacher edition in .github/workflows/regenerate-bundle.yml
# (staff only, ragged, comments), without the blank pages.
STYLES = {
    "teacher": ["--no-tubs", "--ragged", "--no-interior-bars", "--teacher-staff", "--show-comments"],
    "full": [],   # drum staff + Greek and Latin TUBS + count row, as make_rhythm.py
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--yaml", required=True)
    ap.add_argument("--slug", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--style", choices=sorted(STYLES), default="teacher")
    args = ap.parse_args()

    src = Path(args.yaml)
    node = yaml.safe_load(src.read_text(encoding="utf-8"))[args.slug]
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="rhythm-ly-") as td:
        td = Path(td)
        (td / "rhythms").mkdir()
        shutil.copy(src, td / "rhythms" / f"{args.slug}.yaml")
        rp.RHYTHMS_DIR = td / "rhythms"
        rp.OUT_DIR = td / "out"
        rp.REPO = Path("/")          # main() prints paths relative to REPO
        specs = [f"{args.slug}-{v}" for v in node["variations"]]
        sys.argv = ["rhythm_pdf.py", "--title", str(node.get("display", args.slug)),
                    "--include-hidden", "--no-open", *STYLES[args.style], *specs]
        rc = rp.main()
        if rc:
            return rc
        pdfs = sorted((td / "out").glob("*.pdf"))
        if not pdfs:
            print("no PDF produced", file=sys.stderr)
            return 1
        stem = pdfs[0].with_suffix("")
        shutil.move(str(stem.with_suffix(".pdf")), out / f"{args.slug}.pdf")
        if stem.with_suffix(".ly").exists():
            shutil.move(str(stem.with_suffix(".ly")), out / f"{args.slug}.ly")
    print(out / f"{args.slug}.pdf")
    return 0


if __name__ == "__main__":
    sys.exit(main())
