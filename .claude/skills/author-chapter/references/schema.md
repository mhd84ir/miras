# Content schema reference

Distilled from `tool/content_compiler/lib/src/validator.dart` and
`yaml_loader.dart` as of the current codebase. These are the *authored YAML*
field names — they differ from `docs/DATA_MODEL.md`, which documents the
compiled SQLite columns (e.g. YAML `hemistich1` → DB column `hemistich_1`).
If this file and the Dart source ever disagree, the Dart source wins.

## File layout

```
content/chapters/<id>/
  chapter.yaml
  vocab.yaml
  verses.yaml
  retelling.yaml
  lessons/
    01_vocab.yaml
    02_practice.yaml
    ...
```

## ID formats (regex-enforced, all globally unique across the whole content tree)

| Kind | Pattern | Example |
|---|---|---|
| Chapter | `^[a-z][a-z0-9_]*$` | `zahak` |
| Lesson | `^<chapterId>\.l\d{2}$` | `zahak.l03` |
| Exercise | `^<lessonId>\.e\d{2}$` | `zahak.l03.e07` |
| Verse | `^<chapterId>\.v\d{3}$` (3 digits) | `zahak.v012` |
| Vocab | `^vocab\.[a-z][a-z0-9_]*$` | `vocab.kherad` |
| Retelling section | `^<chapterId>\.r\d{2}$` | `zahak.r02` |

IDs are forever once published (a device could reference them in saved
progress) — never rename or reuse one. This mostly matters when *extending*
an existing chapter, not when drafting a brand-new one.

## `chapter.yaml`

```yaml
id: zahak                # required, chapter id regex
position: 2               # required int, must be unique across ALL chapters
title: "..."               # required, Persian
subtitle: "..."            # optional, Persian
summary: "..."             # optional, Persian
cover_asset: ...           # optional string
lessons:                   # required list, must be non-empty
  - lessons/01_vocab.yaml
  - lessons/02_practice.yaml
```

`position` collisions are a validator error — check every existing
`chapter.yaml` under `content/chapters/*/` for the next free number before
picking one.

## `vocab.yaml`

Top-level key: `items:` (list).

```yaml
items:
  - id: vocab.geranmayeh        # required, vocab id regex, unique
    word: "گرانمایه"             # required, Persian
    pronunciation: "gerān-māye"  # required — Latin transliteration (the one field where Latin letters are expected, not just tolerated)
    meaning: "ارزشمند، بزرگوار"  # required, Persian
    etymology: "..."             # optional, Persian
    example_verse: zahak.v002    # optional — must resolve to a real verse id in this chapter
```

## `verses.yaml`

Top-level key: `verses:` (list, narrative order — position is assigned by
list order, not stated explicitly).

```yaml
verses:
  - id: zahak.v001                                    # required, verse id regex, unique
    hemistich1: "یکی مرد بود اندر آن روزگار"            # required, Persian, VERBATIM from Ganjoor
    hemistich2: "ز دشت سواران نیزه گذار"                # required, Persian, VERBATIM from Ganjoor
    meaning: "..."                                      # required, Persian prose (original)
    interpretation: "..."                                # optional, Persian (original)
    vocabulary: [vocab.geranmayeh, vocab.dad_o_dahesh]   # optional — every id must resolve
    source: "ganjoor:/ferdousi/shahname/jamshid/sh2#2"   # convention: ganjoor:<path>#<couplet-index>
```

## `retelling.yaml`

Top-level key: `sections:` (list, order = position).

```yaml
sections:
  - id: zahak.r01              # required, retelling id regex, unique
    body: "..."                 # required, Persian prose (original), multi-paragraph via YAML `>-` block scalar
    illustration_asset: ...     # optional
```

## `lessons/NN_name.yaml`

```yaml
id: zahak.l02              # required, lesson id regex, unique
type: practice              # required, one of: vocab, practice, verses, story, review
title: "..."                 # required, Persian
exercises:                   # required list, non-empty
  - id: zahak.l02.e01        # required, exercise id regex, unique
    type: matching            # required, one of the 10 exercise types below
    difficulty: 1              # optional int 1-3, default 1
    prompt: { ... }            # required map, shape depends on type
```

### Exercise `prompt` shapes (all validator-enforced)

| Type | Prompt fields | Extra rules |
|---|---|---|
| `vocabIntro` | `vocabId` | must resolve to a real vocab id |
| `verseIntro` | `verseId` | must resolve to a real verse id |
| `storySection` | `retellingId` | must resolve to a real retelling section id |
| `matching` | `pairs: [...]` | 2–6 entries, no duplicates, every id a real vocab id |
| `multipleChoice` | `question`, `options: [...]`, `correctIndex`, `vocabId` (optional) | options: 2–5 entries, no duplicates, `correctIndex` in range; `vocabId` if present must resolve |
| `comprehension` | `question`, `options: [...]`, `correctIndex` | same option rules as above; no vocab ref |
| `cloze` | `verseId`, `hemistich` (1 or 2), `blankToken` (int), `options: [...]`, `correctIndex` | **`options[correctIndex]` must literally equal the token at `blankToken` when the given hemistich is split on spaces.** Compute this from the real verse text — don't estimate. Same 2–5/no-duplicate option rules. |
| `listening` | `vocabId`, `options: [...]`, `correctIndex` | `vocabId` must resolve; same option rules |
| `hemistichAssembly` | `verseId`, `hemistich` (1 or 2), `distractors: [...]` (optional) | `distractors` if present must be a list of strings |
| `sequencing` | `events: [{id, text}, ...]`, `correctOrder: [...]` | 3–6 events, unique event ids, non-empty `text`; `correctOrder` must be an exact permutation of the event ids |

Computing `blankToken` for `cloze`: take the exact `hemistich1` or
`hemistich2` string for `verseId`, split on `" "` (single space), and count
0-based to the word you want blanked. Whatever you put at
`options[correctIndex]` must match that word exactly (same normalization,
same characters) or the validator rejects it.

## Persian text hygiene (validator-checked)

- **ASCII digits (`0`–`9`) anywhere in Persian text fields are a hard error.**
  Applies to: chapter `title`/`summary`, verse `hemistich1`/`hemistich2`/
  `meaning`, vocab `word`/`meaning`, retelling `body`. Use Persian digits
  (۰–۹).
- **Latin letters in Persian text fields are a warning**, not an error —
  except `pronunciation`, which is expected to be Latin transliteration.
- ZWNJ (نیم‌فاصله, U+200C) correctness is *not* validator-enforced — it's an
  authoring responsibility. Write it correctly by hand in words like
  «می‌رود»، «داستان‌ها».

## Structural minimums

- Every chapter needs ≥1 lesson.
- Every lesson needs ≥1 exercise.
- Every cross-reference (vocab↔verse, exercise↔vocab/verse/retelling) must
  resolve to a real id within the same validation run.
