# Bundles

Print-quality LilyPond renderings of the rhythm library.

- [`rythmiko-toxo-full-library.pdf`](rythmiko-toxo-full-library.pdf) — every rhythm × every variation in one PDF. Drum staff + Greek TUBS row + Latin TUBS row + count row per variation. Regenerated whenever any `rhythms/<slug>.yaml` changes.
- `*.ly` — the LilyPond source that produced the matching PDF; checked in so anyone can recompile without re-running the Python generator.

See [`../tools/lilypond/README.md`](../tools/lilypond/README.md) for how to regenerate.
