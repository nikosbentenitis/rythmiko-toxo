# rhythm-scan skill: research history

Moved out of `~/.claude/skills/rhythm-scan/SKILL.md` on 23 Oct 2026 so the skill file holds the rules and the pipeline only. Nothing here is a rule; every rule, with Nikos's words and the date, stays in SKILL.md. This file records how the current settings were reached, so a future change does not repeat an experiment that was already rejected.

## The τρίλια timing, in the order it was settled

14 Oct 2026, by ear: Nikos asked for the roll "on the beat", "the 3 tek and the next ka should be equidistant", "the (A) that follows should be later" (than the written 2/3). That gave the first model: the roll starts on the written onset with `trill_strokes` (3) hits, the group's last note lands at `trill_last` (0.8) of the span from the onset to the group end and the roll hits plus every intermediate note are spread evenly up to it, so the teacher's triplet [roll][Α][Ⓐ] played as five equidistant strokes over the beat (tek tek tek Α Ⓐ at 0, .2, .4, .6, .8). A 32nd-note roll and an end-anchored "ruff" were both tried and rejected at that point.

15 Oct 2026, the roll lab was built so the timing could be moved by sliders and compared against five written readings (Teacher, Nikos, Bolder, Kattan, Danziger; the table is in SKILL.md). Nikos: "I like the Bolder writing, keep that". The Bolder lead-in roll is drawn as a VexFlow GraceNoteGroup on the staff. Two attempts to redraw it as a small group in the letter row (first tiny, then grace size, then near full size) were rejected ("it was better before", "go back to the first time you introduced the bolder notation"). The acciaccatura slash was removed because on a beamed group VexFlow drew it over the beams like a roof.

15 Oct 2026, Nikos's own recording (Wahda.m4a): an onset analysis (scratch script, pure Python energy-rise onsets) found a bar of 3.51 s (about 68 BPM) and, in each of the three clean bars, a roll of three hits only about 50 ms apart (a 64th at that tempo) right after a strong stroke and a single stroke 160 ms before the next dum. His words: "I don't get all the tones right but I get the timing of the riff right". His ear that day: "the teks seem to be closer together, almost like 16ths with the first tek somewhere", then "or maybe they are 32nds". The verdict stayed open until 21 Oct.

21 Oct 2026, timed from the recording ("It starts right but the A should be a bit later"): manifest `trill_gap_ms: 55` and `trill_land_ms: 95`, the kah on the group's written onset with the roll before it as a lead-in, each further group note `trill_after_beats: 0.5` after the one before ("That applies to D for the second fingering of the trilia too"); 418 ms measured at 71 bpm. These are the values in force and they are documented as the rule in SKILL.md.

## What is known about the τρίλια (research, 15 Oct 2026)

Full notes with sources are in the skill's own `reference/trilia.md`. The short version:

- Technique: a weak-hand (left) finger roll on the rim; Turkish and Greek style snaps ring, then middle, then index off the thumb, the same three fingers Nikos's teacher uses. Egyptian split-finger (index and ring) and four-finger flicks are the other families. Greek sources call it τρίλια; Siasos's method has a "Τριπλό γκρουπέτο" exercise.
- Timing is not settled anywhere: Bolder's Greek-rhythm book writes the roll as a lead-in in the same cell as the doum or tek it resolves onto (`rD`, `rT`, like a ruff), while Kattan and Danziger count rolls as measured 32nds, triplets or quadruplets. Nikos's ear first put wahda's roll on the beat (measured); the lab's negative Group shift played the lead-in reading for comparison, and the lead-in is what the 21 Oct timing adopted.
- Notation: letter systems use `r`, `rr`, `trr` or a roll-plus-target cell; staff notation uses tremolo strokes (three means unmeasured, fewer means measured) or grace notes (drag is 2, ruff is 3 or more). LilyPond's own rule is `sn8:32` with the beam counting as a slash, which is what the skill's `ka8:32` does. A lead-in would instead be `\grace { ka32 ka ka }` or an LSR 566 `\ruff`. No Greek source shows the hand-written form; the teacher's hatched box is the only evidence.

## Samples

A synth was tried first and rejected ("the sounds are not of a toubeleki"). The real one-shots came from Freesound: hollandm's "Doumbek / darbuka / goblet drum" (CC0) for dum and tek, pjcohen's "Doumbek" pack (CC BY) for ka, kam and the slap. Freesound HQ previews are fetchable without login at `https://cdn.freesound.org/previews/<id[:3]>/<id>_<userid>-hq.mp3` (scrape the search page for ids; about one request every 4 s or the site answers 429). Raw downloads are kept in `samples/raw/`. The first accent gain (1.3 times) was rejected ("you missed the accent … those are louder"); the manifest now carries 2.0 with unaccented tek and ka at 0.55 and 0.45.

## Public page performance (15 Oct 2026)

The first iOS silent-audio workaround used a zero-length base64 clip, which made desktop Chrome re-seek it endlessly at about 350 % CPU while playing (Nikos: "it consumes too many resources"). The fix builds a 2 s WAV in memory (`silentWav`) and creates it only on iOS (`IS_IOS`); the fixed page plays at about 6 %. To measure again: headless Chrome, a CDP click on Play, then `ps`.

## Roll lab drag (15 Oct 2026)

Dragging strokes on the bar strip was tested headlessly by dispatching PointerEvents on a `.grab` rect. The manual layout is saved as `manual-<slug><vN>` in localStorage; any slider or reading button clears it.
