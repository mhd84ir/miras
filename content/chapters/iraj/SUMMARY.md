# ایرج (Iraj) chapter — authoring summary

Chapter position 4, id `iraj` — direct narrative continuation of the shipped
`fereydoon` chapter. All files below live under `content/chapters/iraj/`.
(Originally drafted at position 5; repositioned to 4, with `sohrab` moved to
5, to preserve strict narrative order — Iraj is Fereydun's direct sequel,
while Rostam-o-Sohrab happens generations later.)

## Files produced

- `chapter.yaml` — id `iraj`, position 5, title/subtitle/summary, 6 lessons.
- `vocab.yaml` — 10 vocabulary items.
- `verses.yaml` — 21 couplets (`iraj.v001`–`v021`) in narrative order.
- `retelling.yaml` — 5 simplified-prose sections (`iraj.r01`–`r05`).
- `lessons/01_vocab.yaml`, `02_verses_rashk.yaml`, `03_vocab.yaml`,
  `04_verses_peyman.yaml`, `05_verses_koshtan.yaml`, `06_story_review.yaml`
  (the last mirrors `sohrab.l06`'s combined story+review pattern).

Total for this chapter: 6 lessons, 55 exercises, 10 vocab, 21 verses.
Whole content tree after adding it: **5 chapters, 32 lessons, 283 exercises,
67 vocab, 85 verses.**

## Narrative scope

Salm and Tur's jealousy over Fereydun's division of the world → their
conspiracy → Iraj's pledge of peace and unarmed visit → his murder →
Fereydun's lament. Deliberately stops before Manuchehr's birth/revenge,
which is a distinct, later story.

## Verse sourcing (Ganjoor, `/ferdousi/shahname/fereydoon`)

Continues directly from the `fereydoon` chapter's last verse (sh6#2):

- **sh6** (jealousy ignites, brothers conspire, joint threat to Fereydun)
- **sh7** (Fereydun warns Iraj; Iraj's reply and decision to go unarmed)
- **sh9** (Iraj's arrival; the brothers' envy intensifies)
- **sh10** (the confrontation, Iraj's renunciation, the murder)
- **sh11** (Fereydun's grief, lament, and mourning) — ends at sh11#49

One broad fetch request ("quote couplets 26–38") was declined; re-scoping to
3–4 couplets at a time resolved every case — the curl fallback documented in
the `author-chapter` skill was never needed. All 21 hemistich pairs were
verified character-for-character against saved fetched source text. This
session independently re-verified 4 of the 21 against live Ganjoor pages
(`sh10`, `sh11`) as a spot check — all matched exactly.

## TODO(editorial) items (quoted)

- `chapter.yaml`: "meanings, interpretations, and retelling are original
  drafts pending literary review."
- `vocab.yaml`: "definitions and etymologies pending literary review."
- `verses.yaml`: "meanings and interpretations pending literary review."
- `retelling.yaml`: "Simplified prose retelling — original work.
  TODO(editorial): pending review."

Everything under these markers — all meanings, interpretations, retelling
prose, and exercise question phrasing — is original draft work pending the
project owner's literary review.

## Cross-references to existing chapters

- Reused vocab (not duplicated): `vocab.aaz`, `vocab.khavar` (from
  `fereydoon`); `vocab.shahriar`, `vocab.khorushidan` (from `zahak`, already
  reused by `fereydoon`).
- Internal reuse/callback: `vocab.kehtar` introduced at the brothers'
  grievance, retagged when Iraj turns the same word into his own creed
  ("جز از کهتری نیست آیین من"); `vocab.chin` (چین/wrinkle vs. چین/China
  homograph) introduced on Salm's face (v003), retagged when the same anger
  crosses to Tur's (v012).
- Thematic echoes in `interpretation` prose: Iraj invokes Jamshid's downfall
  directly (v006); the cypress/garden imagery in v015 and v019 calls back to
  `fereydoon`'s own garden verses; the mourning cry in v018 echoes Kaveh's
  cry against Zahhak in the `zahak` chapter.
- `iraj.r01` is a deliberately light recap of the world-division already
  told in full in `fereydoon.r03`–`r04` — not re-authored at length here.

## Validator result

From `tool/content_compiler/`:

```
dart run content_compiler build --strict --content ../../content --out <tmp>
validate: 5 chapters, 32 lessons, 283 exercises, 67 vocab, 85 verses — 0 errors, 0 warnings
```

Clean on the first run, across the whole content tree (not just this
chapter) — independently re-confirmed after the fact, not just self-reported.
