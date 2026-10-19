# Local rhythm editor

A small page and server for editing the rhythms during a lesson, from the iPhone, iPad or Mac, with no GitHub involved. Pick a rhythm, edit a variation with the stroke pad (or the whole YAML), hear it, save.

- `server.py` (standard library plus PyYAML) serves `static/index.html` and a JSON API on port 8817, all interfaces, and keeps `tailscale serve` :9303 mapped to it. A leading `/rhythms` is stripped, so the same server also works behind the hub origin at `/rhythms/`.
- `rhythm_model.py` parses a rhythm with the LilyPond converter's grammar (`tools/lilypond/rhythm_pdf.py`), so tuplets `{3 … }` and the τρίλια `Α8:` work. It returns the diagnostics, the notation data and the timed strokes.
- `static/notation.js` is the web validator's VexFlow staff and TUBS renderer (with tuplet and roll support, from the rhythm-scan skill's `notation.py`).
- `static/player.js` is the rhythm-scan player's engine: the darbuka samples in `samples/`, gains, accents, roll timing, look-ahead scheduler and the iPhone audio handling.
- `render_ly.py` runs `rhythm_pdf.py` on one rhythm in a scratch folder (teacher style and full style).

## Data

`RHYTHM_EDITOR_DATA`, default `~/.local/share/rhythm-editor`:

- `rhythms/<slug>.yaml` is what the editor edits. At start every `rhythms/*.yaml` of this repo that the folder lacks is copied in; an existing file is never overwritten.
- `rhythms/.history/<slug>/<stamp>.yaml` is the version before each save. Revert puts the newest one back and keeps the replaced file as `<stamp>.undone.yaml`.
- `render/<slug>/<sha>/` holds the LilyPond PDFs and PNG pages of the saved version.

Nothing is committed or pushed. To bring edits into the repo, copy `rhythms/<slug>.yaml` from the data folder over `rhythms/<slug>.yaml` here and commit.

## Run

```bash
python3 tools/editor/server.py      # RHYTHM_EDITOR_PORT, RHYTHM_EDITOR_TS_PORT (0 = no tailscale serve), RHYTHM_EDITOR_DATA, RHYTHM_EDITOR_SEED
```
