# Rhythm validator — web app

`index.html` is the browser-based editor and live renderer for rhythms in this repo. It is the **source of truth** for the validator code.

- **Live URL:** <https://bentenitis.com/rhythms>
- **Deployed from:** [`nikosbentenitis/bentenitis`](https://github.com/nikosbentenitis/bentenitis) at `rhythms/index.html` — kept in sync from here by a GitHub Action (see below).

## How it works

A single self-contained HTML file. No build step. The page loads three CDN dependencies at runtime:

- **Pyodide** — runs the YAML parser and rhythm tokenizer in Python in the browser.
- **VexFlow** — renders the 3-line percussion staff.
- **html2pdf.js** — produces the downloadable PDF.

State is held in two places:

- A JS module variable `canonicalYaml` (always in Greek notation), which the UI parses on every keystroke.
- `localStorage` key `rhythmiko_drafts_v1` — autosaved 800 ms after the last keystroke.

The full architecture (token grammar, notation toggle, GitHub OAuth + PR flow, VexFlow specifics, TUBS rendering, PDF page-break handling) is documented inline at the top of the file and in the project root [`README.md`](../README.md).

## Editing

Open `web/index.html` directly in a browser — that's it. Most things work fully offline once the CDN bundles cache. The GitHub-PR flow needs the OAuth Worker at `auth.bentenitis.com`; to test it from a local origin, add `http://localhost:8000` to that Worker's `ALLOWED_ORIGINS`.

For iOS / iPad UX changes there is no shortcut — Safari iOS simulator's behaviour for `inputmode="none"` and `visualViewport` differs from real devices. Test on hardware.

## Deploy / sync to bentenitis

The workflow [`.github/workflows/sync-validator-to-bentenitis.yml`](../.github/workflows/sync-validator-to-bentenitis.yml) opens a PR in `nikosbentenitis/bentenitis` whenever `web/index.html` changes on `main` here.

One-time setup:

1. Create a **fine-grained personal access token** at <https://github.com/settings/tokens?type=beta> scoped to **only** the `nikosbentenitis/bentenitis` repo, with these permissions:
   - Contents: Read and write
   - Pull requests: Read and write
2. Add it as a repository secret in this repo named `BENTENITIS_SYNC_TOKEN` (Settings → Secrets and variables → Actions → New repository secret).

After that, every push to `main` touching `web/index.html` opens (or fast-forwards) a PR `sync/rhythm-validator` in `bentenitis`. Merge it to deploy. The workflow can also be triggered manually from the Actions tab.

## File map (approximate; line numbers drift)

| Feature | Range |
|---|---|
| CSS | 6–340 |
| HTML body | 365–415 |
| Python parser (Pyodide) | 420–620 |
| Notation toggle helpers | 660–760 |
| GitHub OAuth + PR flow | 760–1100 |
| Local drafts + offline | 1100–1280 |
| Variations management + comments | 1280–1620 |
| Token palette + iOS adaptation | 1620–1750 |
| Rendering (TUBS / staff / staves) | 1750–1900 |
