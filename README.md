# rythmiko-toxo

A community-editable library of Middle-Eastern and Greek darbuka/doumbek rhythms in a small YAML format. Each rhythm lives in its own file under [`rhythms/`](rhythms/) and can be edited online from the rendering & validation tool at **https://bentenitis.com/rhythms**.

The validator lets you:

1. Pick a rhythm from this repository.
2. Edit the YAML in your browser, with live notation rendering (TUBS grid + Western staff via VexFlow) and diagnostics.
3. Sign in with GitHub and submit your change as a pull request — no local checkout required. PRs land here for review.

## File format

One YAML file per rhythm, keyed by an English slug. The slug appears both as the filename (`rhythms/<slug>.yaml`) and the root key inside the file.

```yaml
duyek:
  display: "Duyek"
  meter: "4/4"
  variations:
    v1:
      rhythm: ">8[ S8] r8 S8 >4 S4"
    v2:
      rhythm: ">8[ Δ16 Α16] Δ8[ (Α)8] >16[ Α16 Δ8] >4"
    v3:
      rhythm: ">8[ Δ16 Α16] r16 Δ16[ (Α)16] r16 S16[ Α16 S16 A16] >4"
```

### Required keys

- `<slug>` — top-level mapping; must match the filename.
- `display` — human-readable name (Greek, Turkish, etc.).
- `meter` — `numerator/denominator`, e.g. `4/4`, `9/8`, `7/8`. Shared by all variations; a variation may override.
- `variations` — at least one variation, keyed `v1`, `v2`, …

### Optional keys

- `boxes_per_beat` — TUBS grid resolution per beat. Auto-derived from the smallest duration if omitted.
- `single_line: true` — render the variation on a single line (used for very long bars).

## Rhythm-string syntax

A `rhythm:` value is a space-separated list of tokens, with bar separators `|`. Each token is `<head><duration?><accent?><beam?>`.

### Strokes (head)

| Symbol | Word | Drum stroke |
|---|---|---|
| `>`    | `D` / `dum`  | dum (low, open) |
| `Δ`    | `tek`        | tek (high, edge) — capital = accented; lowercase `δ` = unaccented |
| `Α`    | `A` / `ka`   | kah (ring finger) — capital = accented; lowercase `α` = unaccented |
| `(Α)`  | `(ka)`       | kah played with the middle finger; renders circled |
| `S`    | `H` / `slap` | slap |
| `r`    | `r`          | rest |

Symbol and word notations are interchangeable within a variation.

### Duration

- `4` quarter, `8` eighth, `16` sixteenth, `2` half, `1` whole. `.` after a number → dotted (1.5×).
- Duration is **sticky**: if a token has no duration, it inherits the previous one. Example: `Δ16 Α Δ8 Α` means two sixteenths followed by two eighths.

### Accent

- For tek / kah only. Capital-letter form (`Δ`, `Α`) is implicitly accented; lowercase (`δ`, `α`) is not.
- In word notation, an explicit `^>` after a token marks an accent: `tek8^>`, `ka16^>`.

### Beam

- `[` opens a beam group, `]` closes it. Joins the notes visually under one beam in the staff render.
- Example: `>8[ Δ16 Α16] r8 …` — the dum and the two sixteenths share a beam.

### Bars

- Separate bars with `|`.
- Use `%` as a whole bar to repeat the previous bar verbatim.

## Contributing a change

1. Open https://bentenitis.com/rhythms.
2. Pick a rhythm in the sidebar — its YAML loads into the editor.
3. Edit. Watch diagnostics & rendering update live. Use **Download PDF** to print a copy locally.
4. Click **Sign in with GitHub** (top-right of the editor). One time only; uses standard GitHub OAuth.
5. Click **Submit pull request**. The tool will:
   - Fork `nikosbentenitis/rythmiko-toxo` into your account (idempotent).
   - Create a branch named `edit-<slug>-<timestamp>` on your fork.
   - Commit your edited YAML.
   - Open a PR back to `main` here.
6. A link to the PR is shown; review happens in the GitHub UI.

You can also clone this repo and edit locally — the PR flow above is for convenience, not the only path.

## Repository layout

| Path | What it is |
|---|---|
| [`rhythms/`](rhythms/) | One YAML file per rhythm — the canonical content of this library. |
| [`web/`](web/) | The browser-based validator (single-file HTML + CDN deps). Source of truth for the app code; see [`web/README.md`](web/README.md). |
| [`worker/`](worker/) | Cloudflare Worker that brokers GitHub OAuth for the in-browser PR flow. |
| [`tools/lilypond/`](tools/lilypond/) | Offline LilyPond toolchain that emits print-quality PDFs into [`bundles/`](bundles/). |
| [`bundles/`](bundles/) | LilyPond-rendered PDFs (full-library + per-section). |
| [`.github/workflows/`](.github/workflows/) | CI — including the auto-sync that mirrors `web/index.html` into the deploy repo. |

The validator at <https://bentenitis.com/rhythms> is served from [`nikosbentenitis/bentenitis`](https://github.com/nikosbentenitis/bentenitis) (private) at `rhythms/index.html`. That file is **automatically synced** from [`web/index.html`](web/index.html) here by a GitHub Action; do not edit the bentenitis copy by hand.

## License

Content here (the rhythm definitions) is offered under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) — no rights reserved; reuse freely.
