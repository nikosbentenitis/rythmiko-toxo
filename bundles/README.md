# Bundles

Print-quality LilyPond renderings of the rhythm library.

- [`rythmiko-toxo-full-library.pdf`](rythmiko-toxo-full-library.pdf) — every rhythm × every variation. Drum staff + Greek TUBS + Latin TUBS + count row per variation. One rhythm per page, with a clickable table of contents.
- [`rythmiko-toxo-full-library-teacher.pdf`](rythmiko-toxo-full-library-teacher.pdf) — same layout, **drum staff only** (no TUBS rows), plus **5 blank pentagrams** per rhythm so a teacher can write extra variations directly on the PDF (e.g. on a Remarkable). Same TOC + page-per-rhythm structure.
- `*.ly` — the LilyPond source that produced the matching PDF; checked in so anyone can recompile without re-running the Python generator.

Both PDFs regenerate automatically on every push to `main` that changes `rhythms/**` or `tools/lilypond/**`.

See [`../tools/lilypond/README.md`](../tools/lilypond/README.md) for how to regenerate.
