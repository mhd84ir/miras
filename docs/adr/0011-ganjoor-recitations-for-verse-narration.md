# ADR-0011: Ganjoor recitations (آوای گنجور) for verse narration

**Status:** Accepted (2026-07-09) · sourcing chosen by project owner in the M6+ plan

## Context

Verse audio needs human-quality recitation: ADR-0005 de-emphasized synthesized
couplets, and the accepted-for-beta Piper voice (ADR-0008) is below the bar
for poetry. آوای گنجور hosts crowd-contributed recitations of the exact
Ganjoor poems our verses cite, with per-hemistich sync timings and terms
permitting reuse with narrator + source attribution. Candidates: import those
recitations, record narration ourselves, or wait for a commercial Persian TTS.

## Decision

Import **آوای گنجور recitations**, sliced per couplet by the compiler's
`import-narration` command using each recitation's sync XML. Clips are
committed **ID-addressed** (`content/narration/<chapter>/<verseId>.mp3`) with
provenance JSON; `build` overlays them over any synthesized verse audio and
ships attribution in a new pack `credits` table (schema v2), which the app
shows under the library verses list.

## Rationale

- Real human recitation of the exact couplets, at zero recording cost, from
  the same source of truth as the verse text — provenance refs
  (`ganjoor:<path>#<couplet>`) already locate the audio precisely.
- ID-addressed storage, not the TTS content-hash cache: a recording is a
  fact about (poem, couplet, narrator), not a function of our text — text
  polishing must not orphan it, and mixed TTS/narration sources cannot share
  one cache identity.
- Attribution inside the pack keeps the legal obligation attached to the
  content it covers, wherever the pack travels (APK today, CDN later).
- Rejected: **synthesized verse audio as the end state** — ADR-0005 already
  called recitation quality inadequate; the beta keeps it only as a fallback
  for chapters not yet imported.
- Rejected: **recording narration ourselves** — recording logistics gate
  every content release (rejected once in ADR-0005), and quality would start
  below experienced narrators.
- Rejected: **waiting for commercial TTS (ivira.ai)** — that path is for
  vocabulary words; measured poetry recitation is precisely where synthesis
  is weakest.

## Consequences

- Narrator choice is editorial: the importer defaults to each poem's first
  synced recitation (`--artist` overrides); the owner auditions clips before
  they ship, like all audio.
- Committed clip weight grows with coverage (~1.3 MB for zahak's 22 verses;
  ~5–6 MB projected for all five chapters) in repo and APK alike.
- Slice boundaries come from crowd-made sync data — a sloppy sync means a
  clipped or overlong clip; the audition pass is the quality gate, and a bad
  poem can be re-imported with a different `--artist`.
- Recitations vary in narrator, pace, and recording quality across poems; a
  chapter can mix narrators (attribution lists all of them).
- Pack schema v2 (credits table) obliges the app-side Drift schema to stay
  in lockstep; older app builds cannot read v2 packs — acceptable because
  pack and app still ship together (ADR-0010 defers independent delivery).
