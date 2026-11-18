# Notation guidelines

Approved by Nikos on 18 Nov 2026 after the arabesque whiteboard. They govern every rendering of the library: the LilyPond PDFs (`tools/lilypond/rhythm_pdf.py --scan-style`) and the web pages on bentenitis.com/rhythms (`rhythm-scan/scripts/notation.py`, built with `build_public.py`, style `scan`).

## Transcription

- The scan is the authority. Every beam, rest, accent, circled kah and stroke is transcribed as the scan draws it, and a rendering is checked against the scan side by side before it is published.
- Each beat is one beamed group. The dum that starts a beat is beamed into that group (`>8[ Δ16 Α16]`), never left as a standalone quarter when the scan beams it.
- Rests sit where the scan draws them. When the scan's beam runs over a rest, the rest is inside the beam (`>16[ Α16 r16 (Α)16]`).
- Each arabesque variation is one 4/4 bar; the gap the teacher leaves between beats 2 and 3 is phrasing, not a bar line.

## Scan style (the library default)

- No staff lines, no clef, no system bracket and no bar lines. The time signature is written as numbers (4/4).
- Tek and ka sit on one level, with short stems of equal length.
- The dum sits lower, so its stem is longer. Its length is 3/4 of the first cut (PDF staff position -2 against +1 for tek/ka; web key b/4 against e/5).
- The slap is an x notehead at the bottom of the note, at the dum's level, with a stem as long as the dum's.
- Every beam in a row sits at one height, whatever notes it joins (eighths, sixteenths, a dum group or a tek/ka group).
- The dum never carries the second (sixteenth) beam line. A tek or ka next to it keeps its own short stub, so its sixteenth value still reads.
- Accents (`>`) sit above the beam with a small gap, never on it.
- Rests are drawn larger and raised to beam height between groups, as the 7-shaped rests on the whiteboard. A rest inside a beam sits just under the beam.
- The letter row (`>`, Δ, Α, circled Α, S) sits just under the dum, and every letter, the slap's S included, shares one baseline.
- The TUBS boxes and count rows are unchanged from the staff style.

## Player pages

- By default each variation plays once, in order (1, 2, 3). The MP3 bundle is also one pass per variation.
- The whole page scrolls as one, on a phone above all. The play and tempo panel is not sticky and the variations are not in a separate scrolling frame.
