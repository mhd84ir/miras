---
name: author-chapter
description: >-
  Draft-assists authoring of Shahnameh chapter content (vocab, verses,
  retelling, lesson/exercise YAML) for the Miras app, matching the exact
  schema the Dart content compiler validates. Use whenever the task is to
  author, draft, extend, or fix content under content/chapters/ in the Miras
  repo — e.g. "author the Fereydun chapter", "add a review lesson to
  Zahhak", "draft vocab for chapter X", "why is content_compiler validate
  failing on my YAML", or anything about Ganjoor-sourced verses, exercise
  prompt schemas, or the content pipeline. Always consult this before
  hand-writing chapter YAML from memory — the schema has sharp edges
  (exact field names, ID regexes, cross-reference rules) that are easy to
  get subtly wrong without it.
---

# Author Chapter

Drafts a Shahnameh chapter's authored YAML content end-to-end: `chapter.yaml`,
`vocab.yaml`, `verses.yaml`, `retelling.yaml`, and `lessons/*.yaml`, in the
exact shape `tool/content_compiler` accepts.

## The one rule that matters most

**Verse text (`hemistich1`/`hemistich2`) is transcription, not authorship.**
Everything else in a chapter — meanings, interpretations, retelling prose,
etymologies, exercise questions — is original work you may draft freely. The
couplets themselves are Ferdowsi's, sourced verbatim from Ganjoor
(ganjoor.net), and the project's own integrity rests on never silently
paraphrasing or inventing a hemistich. If you can't fetch or verify the actual
source text for a couplet, say so explicitly and stop rather than produce a
plausible-sounding line — a fabricated "verbatim" verse is worse than a gap,
because nothing will ever catch it later.

Everything you draft that *is* original interpretive work (meanings,
interpretations, etymologies, retelling body text, comprehension/sequencing
question text) gets marked pending review — see "Draft-assist marking" below.
This split is what makes it safe for this skill to move fast: the
irreplaceable, unverifiable part (the verse itself) is handled with maximum
care; the reviewable part is handled with maximum speed, because a human is
always going to look at it before it ships.

## Why a skill for this at all

The YAML *looks* like it'd be easy to hand-write, but the compiler
(`tool/content_compiler/lib/src/validator.dart`) enforces exact ID regexes,
per-exercise-type field shapes, and — for `cloze` exercises — that
`options[correctIndex]` literally equals the real hemistich token at
`blankToken` (computed by splitting the hemistich on spaces). Getting any of
this wrong doesn't fail loudly in the app; it fails as a CI validation error
or, worse, a silently-wrong exercise. Read `references/schema.md` before
drafting exercises — it's the compiler's rules distilled, verified directly
against the Dart source (not the architecture docs, which describe the
*compiled* DB schema and use different field names than the authored YAML —
e.g. YAML uses `hemistich1`, the DB column is `hemistich_1`).

## Draft-assist marking

Follow the convention already used in every existing chapter file — see any
file under `content/chapters/*/`. At the top of a file with original literary
content, add:

```yaml
# TODO(editorial): meanings, interpretations, and retelling are original drafts
# pending literary review.
```

Anything you draft that's a judgment call — a vocab meaning, a verse
interpretation, a retelling paragraph, a comprehension question's phrasing —
lives under that umbrella. Don't present it as final; the project owner
reviews it before it's treated as accurate. `chapter.yaml` additionally
documents its Ganjoor source range in a leading comment (copy the pattern from
`content/chapters/zahak/chapter.yaml`).

## Workflow

1. **Gather inputs.** Chapter id (lowercase slug), the story's Ganjoor source
   locations (e.g. `/ferdousi/shahname/zahak`, sections/couplet ranges), and
   the next unused `position` number (check existing `chapter.yaml` files).
   If any of this is missing, ask rather than guess — position collisions and
   wrong source ranges are exactly the kind of error the validator won't
   catch for you (position uniqueness it *does* catch; source-range accuracy
   it can't).

2. **Read two or three lesson files from an existing chapter first.** Chapters
   under `content/chapters/` (jamshid, zahak, fereydoon, sohrab) are the house
   style/tone/difficulty reference — not just for schema shape but for how
   plain the Persian is, how much interpretation accompanies a verse, and how
   the vocab→practice→verses→story→review arc paces out. Don't skip this even
   if `references/schema.md` already told you the shape.

3. **Fetch and transcribe verses** (`verses.yaml`), in narrative order, from
   the actual Ganjoor pages for the given source range. Pull difficult/archaic
   words out into `vocab.yaml` as you go, cross-referencing via `vocabulary:`
   on the verse and `example_verse:` on the vocab item. A curated selection of
   the most narratively load-bearing couplets is normal and matches house
   style (existing chapters transcribe a fraction of their source range, not
   every couplet on every page) — you don't need to include everything you
   fetch.

   **Fetch verses individually or a few at a time** (e.g. "does this page
   contain couplets X and Y, quote them" rather than "transcribe this whole
   page" or "list every couplet on this page"). This is the scope a
   citation/verification request should have anyway, since you're selecting a
   curated subset, not transcribing full pages — and in practice it's also
   what reliably avoids fetch-tool declines. A broad "give me everything on
   this page" request is far more likely to read as bulk reproduction and get
   declined than the same information gathered a few couplets at a time. If a
   request comes back ambiguous (e.g. an unclear line split), re-fetch that
   specific couplet more narrowly rather than guessing.

   **If a narrow, specific request is still declined**, don't reach for a
   technical workaround (e.g. curl-fetching the raw page yourself) as a
   matter of course — that was tried once for this project with explicit
   owner authorization, and a stricter permission layer in the execution
   environment still blocked it, independently of the tool-level decline.
   Two independent layers agreeing is a reasonable place to stop, not push
   past. In practice this has not been needed: re-scoping to a smaller,
   specific request has always resolved the decline. If it genuinely doesn't,
   stop and ask the project owner how they want to source that couplet
   (they may prefer to paste it themselves) rather than trying to route
   around the decline yourself.

   **Before moving on, verify what you drafted against what you fetched.**
   Write a quick script that compares every hemistich you put in
   `verses.yaml` character-for-character against your saved source text.
   `content_compiler validate` has no ground truth to check verbatim accuracy
   against, so it will happily pass a verse with a wrong couplet citation or
   a stray/missing ZWNJ — this cross-check is the only thing that catches
   that class of error, and it does catch real mistakes in practice.

4. **Draft `retelling.yaml`** — simplified-Persian prose sections that cover
   the verses' narrative, original work.

5. **Draft `chapter.yaml`** — title/subtitle/summary plus the ordered lesson
   list, following the five-part arc from `docs/PRD.md` §5.1
   (`vocab → practice → verses → story → review`), repeated across multiple
   "acts" for longer stories.

6. **Draft `lessons/*.yaml`** exercises per lesson type. For every `cloze`,
   actually split the target hemistich on spaces and index into it — don't
   estimate `blankToken`. See `references/schema.md` for the full per-type
   field reference.

7. **Validate and iterate.** From `tool/content_compiler/`, run:

   ```sh
   dart run content_compiler validate --content <path-to-content-dir>
   ```

   Fix every reported error before calling the draft done. This is not
   optional and not a formality — it's the only mechanical check that IDs,
   cross-references, and exercise schemas are actually correct; nothing about
   how plausible the YAML looks tells you that.

8. **Summarize.** List every file written, every `TODO(editorial)` item (so
   the owner knows exactly what to review), and any verse/source gaps you
   flagged instead of guessing. State plainly that this is a draft pending
   literary review, not finished content.

## Before trusting this on genuinely new content

Trial it first on a chapter that's already authored and committed (e.g.
re-derive `zahak` into a scratch directory, *not* over the real
`content/chapters/zahak/`) and diff the result against the real files for
tone, accuracy, and schema cleanliness. That comparison is the calibration
step — it tells you concretely where this workflow's drafts diverge from the
project's actual quality bar before you rely on it for a story with no ground
truth to check against.

## Reference

- `references/schema.md` — exact ID regexes, per-exercise-type prompt fields,
  and every validator constraint (option counts, Persian-digit hygiene, etc.),
  distilled from `tool/content_compiler/lib/src/validator.dart` and
  `yaml_loader.dart`. Re-check those two files directly if something here
  seems off — they're the ground truth and this file can drift.
- `docs/CONTENT_GUIDE.md`, `docs/DATA_MODEL.md` — project-level authoring
  guide and compiled-schema reference (note the DB-column-name vs
  YAML-field-name difference mentioned above).
- Any `content/chapters/<story>/` directory — worked examples of house style.
