#!/usr/bin/env python3
"""Print the space-separated list of rhythm specs (slug-vN) for the
LilyPond bundle generator, in the canonical bundle order.

Order:
  1. All rhythms (alphabetical by slug), EXCEPT the trailing group.
  2. The trailing group, in the order specified below.

Usage:
  python3 tools/lilypond/list_specs.py
"""

from __future__ import annotations

import glob
import sys

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is required: pip install pyyaml")


# Slugs forced to the end of the bundle, in this exact order. Any rhythm
# not listed here is emitted first, alphabetically by slug.
TRAILING_SLUGS = ["sofyan", "nim_sofyan", "kasik_havasi", "azeri"]


def main() -> int:
    head: list[str] = []
    tail: dict[str, list[str]] = {s: [] for s in TRAILING_SLUGS}
    for path in sorted(glob.glob("rhythms/*.yaml")):
        with open(path) as f:
            doc = yaml.safe_load(f)
        for slug, body in doc.items():
            for v in (body.get("variations") or {}):
                spec = f"{slug}-{v}"
                (tail[slug] if slug in tail else head).append(spec)
    ordered = head + [spec for s in TRAILING_SLUGS for spec in tail[s]]
    print(" ".join(ordered))
    return 0


if __name__ == "__main__":
    sys.exit(main())
