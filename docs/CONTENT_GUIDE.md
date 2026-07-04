# Content Authoring Guide

How lesson content is authored, validated, and compiled. Audience: content
authors and developers. The app never reads YAML — everything below is compiled
into a SQLite pack by `tool/content_compiler`.

## Layout

```
content/
  chapters/
    <chapter>/               e.g. zahak/
      chapter.yaml           metadata + ordered lesson list
      vocab.yaml             vocabulary items introduced in this chapter
      verses.yaml            couplets with meanings (order = narrative order)
      retelling.yaml         simplified prose retelling, in sections
      lessons/
        01_vocab.yaml        one file per lesson, ordered by chapter.yaml
        02_practice.yaml
```

## Commands (run in `tool/content_compiler/`)

```sh
dart run content_compiler validate --content ../../content
dart run content_compiler build --content ../../content --out ../../build/pack
dart run content_compiler build --strict --tts azure ...   # release mode
```

`validate` prints every issue with file + path; `build` additionally emits
`miras_content.db` and (when TTS is configured) `audio/*.mp3`. `--strict`
turns warnings into failures — CI uses it for release packs.

## IDs are forever

IDs are stable, human-readable, and referenced by user progress on devices.
**Never rename or reuse a published ID** (docs/DATA_MODEL.md invariant 1).

| Kind | Format | Example |
|---|---|---|
| Chapter | `[a-z][a-z0-9_]*` | `zahak` |
| Lesson | `<chapter>.lNN` | `zahak.l03` |
| Exercise | `<lesson>.eNN` | `zahak.l03.e07` |
| Verse | `<chapter>.vNNN` | `zahak.v012` |
| Vocabulary | `vocab.<slug>` | `vocab.kherad` |
| Retelling section | `<chapter>.rNN` | `zahak.r02` |

## Persian text rules

- Write naturally; the compiler normalizes Arabic ي/ك to Persian ی/ک,
  Arabic-Indic digits to Persian digits, and cleans stray ZWNJ/whitespace.
- **Use correct ZWNJ (نیم‌فاصله)**: «داستان‌ها»، «می‌رود». The compiler
  preserves it; missing ZWNJ is an authoring error it cannot detect.
- **ASCII digits (0–9) in Persian text are a build error** — use ۰–۹.
- `pronunciation` fields are Latin transliteration (e.g. `kāve`) — the one
  place Latin is expected.
- Verse text must match the Ganjoor source exactly; record provenance in
  `source:` (`ganjoor:<url>#<couplet-index>`). Meanings and interpretations
  are original work — keep them modern, plain Persian.

## Lesson types and the chapter arc

`vocab` → `practice` → `verses` → `story` → `review` (docs/PRD.md §5.1).
Longer chapters repeat the arc. Exercise types and their prompt schemas are
specified in docs/DATA_MODEL.md §3; the validator enforces every schema,
including that a cloze's correct option equals the actual blanked verse token
(`blankToken` is a 0-based space-separated token index).

## Audio

Vocabulary words and verses get TTS audio at build time (ADR-0005), cached by
content hash in `tool/content_compiler/.cache/` (gitignored). Without a
configured TTS backend, packs build with null audio and the app hides
listening exercises — authoring them is still correct; they activate when
audio exists. Azure backend: set `AZURE_SPEECH_KEY` + `AZURE_SPEECH_REGION`.

## Review workflow

Content changes go through PRs like code: CI validates the whole content tree
on every push. Meanings/interpretations authored without a literary editor are
tagged with a `# TODO(editorial)` comment in YAML until reviewed.
