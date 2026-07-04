# Data Model — Miras

Two physically separate SQLite databases (via Drift):

- **Content store** — read-only, produced by the content compiler, replaced atomically
  on pack update. The app never writes to it.
- **User store** — mutable, on-device, schema-migration-managed. References content
  by stable string IDs (never by foreign key into the content DB, since packs are
  replaceable).

Content IDs are human-readable, stable, and immutable across pack versions:
`zahhak` (chapter) · `zahhak.l03` (lesson) · `zahhak.l03.e07` (exercise) ·
`zahhak.v012` (verse) · `vocab.kherad` (vocabulary item).

---

## 1. Content store

### `content_pack` (single row)
| Column | Type | Notes |
|---|---|---|
| `pack_version` | int | Monotonic |
| `schema_version` | int | App refuses packs with unknown schema versions |
| `checksum` | text | Integrity of pack + assets |
| `built_at` | text (ISO-8601) | |

### `chapters` — a story (داستان)
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | e.g. `zahhak` |
| `position` | int | Order on the learning path |
| `title` | text | Persian, e.g. «ضحاک و کاوهٔ آهنگر» |
| `subtitle` | text | One-line Persian teaser |
| `summary` | text | Short Persian synopsis (library view) |
| `cover_asset` | text | Illustration reference |

### `lessons`
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | e.g. `zahhak.l03` |
| `chapter_id` | text FK | |
| `position` | int | |
| `type` | text enum | `vocab · practice · verses · story · review` |
| `title` | text | Persian |

### `exercises`
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | e.g. `zahhak.l03.e07` |
| `lesson_id` | text FK | |
| `position` | int | |
| `type` | text enum | 8 types, see §3 |
| `prompt_json` | text | Typed payload per exercise type (§3) |
| `difficulty` | int 1–3 | Used for review mixing |

### `vocabulary_items`
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | e.g. `vocab.kherad` |
| `word` | text | «خرد» |
| `pronunciation` | text | Latin phonetic: `kherad` |
| `meaning` | text | Modern Persian: «عقل، دانایی» |
| `etymology` | text nullable | Short Persian note |
| `audio_asset` | text | |
| `example_verse_id` | text nullable | |
| `first_chapter_id` | text | Where it is introduced |

### `verses` — one row per بیت (couplet)
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | e.g. `zahhak.v012` |
| `chapter_id` | text FK | |
| `position` | int | Narrative order within chapter |
| `hemistich_1` | text | مصراع اول |
| `hemistich_2` | text | مصراع دوم |
| `meaning` | text | Modern-Persian prose meaning |
| `interpretation` | text nullable | Longer note: context, imagery, notable vocabulary |
| `audio_asset` | text nullable | |

### `verse_vocabulary` (join)
`verse_id` · `vocabulary_item_id` — enables tap-a-word-in-verse lookup.

### `retellings`
| Column | Type | Notes |
|---|---|---|
| `id` | text PK | |
| `chapter_id` | text FK | |
| `position` | int | Section order |
| `body` | text | Simplified Persian prose |
| `illustration_asset` | text nullable | |

---

## 2. User store

All mutable tables carry `created_at` / `updated_at` (ISO-8601) for future sync.

### `user_profile` (single row)
`id` (local UUID) · `created_at` · `daily_xp_goal` (int, default 20) ·
`notifications_enabled` · `sound_enabled` · `theme_mode`

### `lesson_progress`
| Column | Type | Notes |
|---|---|---|
| `lesson_id` | text PK | Content ID (string reference, not FK) |
| `status` | text enum | `locked · available · completed` (derived + cached) |
| `stars` | int 0–3 | From accuracy: <80% → 1, <100% → 2, 100% → 3 |
| `best_accuracy` | real | |
| `completed_at` | text nullable | |

### `exercise_attempts` (append-only log)
`id` · `exercise_id` · `was_correct` · `answered_at` · `lesson_session_id`
— feeds difficulty tuning and future analytics; prunable.

### `srs_cards` — one per vocabulary item once first encountered (FSRS state)
| Column | Type | Notes |
|---|---|---|
| `vocabulary_item_id` | text PK | |
| `state` | text enum | `new · learning · review · relearning` |
| `stability` | real | FSRS memory stability (days) |
| `difficulty` | real | FSRS difficulty (1–10) |
| `due_at` | text | Next review timestamp |
| `last_reviewed_at` | text nullable | |
| `reps` | int | |
| `lapses` | int | |

### `xp_events` (append-only)
`id` · `amount` · `source` (`lesson · review · achievement`) · `source_id` · `earned_at`
— daily totals are aggregated by query; the event stream is the future leagues feed.

### `streak` (single row)
`current` · `longest` · `last_active_date` (local date) · `freezes_available` ·
`freeze_used_dates`

### `hearts` (single row)
`count` (0–5) · `last_refill_at` — refill computed lazily on read (no background jobs).

### `achievements`
`achievement_id` (from static app-side catalog) · `unlocked_at`

---

## 3. Exercise `prompt_json` schemas

Persian examples use the Shahnameh's opening: «به نام خداوندِ جان و خرد / کزین برتر اندیشه برنگذرد»

| Type | Schema (fields) |
|---|---|
| `vocabIntro` | `{ "vocabId": "vocab.kherad" }` — presentation; renders from vocabulary table |
| `verseIntro` | `{ "verseId": "zahak.v001" }` — presentation; couplet + meaning + interpretation |
| `storySection` | `{ "retellingId": "zahak.r01" }` — presentation; one retelling section |
| `matching` | `{ "pairs": ["vocab.kherad", "vocab.andisheh", "vocab.shahriar", "vocab.anjoman"] }` |
| `multipleChoice` | `{ "question": "معنی «خرد» چیست؟", "options": ["عقل و دانایی", "کوچک", "شادمانی", "پادشاهی"], "correctIndex": 0, "vocabId": "vocab.kherad" }` |
| `cloze` | `{ "verseId": "zahak.v001", "hemistich": 1, "blankToken": 5, "options": ["خرد", "هنر", "سخن", "روان"], "correctIndex": 0 }` — compiler verifies `options[correctIndex]` equals the blanked token |
| `listening` | `{ "vocabId": "vocab.kherad", "options": ["خرد", "خورد", "گرد"], "correctIndex": 0 }` — audio comes from the vocab item's `audio_asset`; app skips the exercise if audio is absent |
| `hemistichAssembly` | `{ "verseId": "zahak.v001", "hemistich": 2, "distractors": ["جهان", "سخن"] }` — correct tiles derived from verse text |
| `comprehension` | `{ "question": "کاوه چرا برخاست؟", "options": [...], "correctIndex": 1 }` |
| `sequencing` | `{ "events": [{"id": "a", "text": "..."}, ...], "correctOrder": ["c", "a", "b", "d"] }` |

The compiler validates every payload against these schemas at build time; the app
deserializes into sealed Dart classes (`sealed class ExercisePrompt`), so an unknown
type is a compile-time-adjacent failure, not a runtime surprise.

---

## 4. Gamification rules (domain constants — single source of truth in code)

| Rule | Value (initial; tunable) |
|---|---|
| XP: lesson completed | 10 |
| XP: perfect lesson bonus | +5 |
| XP: review session | 5 (+5 if all correct) |
| Hearts | Max 5; −1 per wrong answer in lessons; review sessions never cost hearts |
| Heart refill | 1 per 4h (lazy computation), or full refill on completing a review session |
| Streak day | ≥1 lesson or review session completed (local timezone) |
| Streak freeze | Earned at streak milestones (7, 30, …); max 2 held; auto-consumed |
| Stars | accuracy <80% → ★ · <100% → ★★ · 100% → ★★★ |

## 5. FSRS (spaced repetition) integration

- Review grades map from exercise outcomes: wrong → `again`, correct-with-hesitation
  (>N s) → `hard`, correct → `good` (explicit `easy` available in review UI).
- Scheduler is a pure-Dart implementation of FSRS in `domain` with the published
  default parameters; per-user parameter optimization is out of scope for MVP.
- A review session drains due cards (capped at 20/session) mixing exercise types
  (MCQ, matching, listening) over the same vocabulary.

## 6. Invariants

1. Content IDs never change meaning across pack versions; removal is deprecation
   (kept, hidden), never deletion, so user progress never dangles.
2. The app never writes to the content store; the compiler never touches user data.
3. All timestamps stored UTC ISO-8601; streak day boundaries computed in the user's
   local timezone at read time.
4. `xp_events` and `exercise_attempts` are append-only; aggregates are derived.
5. Runtime never normalizes content text (that is a compiler responsibility);
   the app trusts pack text byte-for-byte, ZWNJ included.
