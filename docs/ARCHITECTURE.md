# Architecture — Miras

Flutter client, local-first, content compiled offline into versioned packs.
Decisions with lasting consequences are recorded as ADRs in [adr/](adr/).

## 1. System overview

```
┌────────────────────────── development time ──────────────────────────┐
│  content/ (YAML, authored)                                           │
│      │                                                               │
│      ▼                                                               │
│  tool/content_compiler (Dart CLI)                                    │
│   · schema validation      · Persian normalization (ی/ک, ZWNJ)       │
│   · TTS audio generation (cached)                                    │
│   · emits versioned content pack (SQLite + audio/illustration assets)│
└──────────────────────────────┬────────────────────────────────────---┘
                               │  bundled in app assets (MVP)
                               │  later: uploaded to static CDN
                               ▼
┌────────────────────────────  app (Flutter)  ──────────────────────---┐
│ presentation (widgets, Riverpod consumers)                           │
│ application  (controllers/notifiers, use-case orchestration)         │
│ domain       (pure Dart: entities, FSRS, XP/streak/hearts rules)     │
│ data         (repositories over two Drift databases)                 │
│    · ContentDatabase  — read-only pack, swapped atomically on update │
│    · UserDatabase     — mutable, migration-managed                   │
└──────────────────────────────────────────────────────────────────────┘
```

There is **no server in phase 1.** The seam for a future backend (accounts, sync,
leagues) is the repository interfaces in the data layer — see §9.

## 2. Repository layout

```
app/                       Flutter application (see §3)
content/                   Authored YAML, one directory per story
  chapters/<story>/        chapter.yaml, lessons/, vocab.yaml, verses.yaml, retelling.yaml
tool/content_compiler/     Dart CLI package (pure Dart, no Flutter dependency)
docs/                      This documentation + ADRs
.github/workflows/         CI
```

## 3. App architecture

Feature-first with layered features:

```
app/lib/
  main.dart                bootstrap (DB init, pack load, ProviderScope)
  app.dart                 MaterialApp.router, fa locale, theme
  core/
    theme/                 design tokens (MirasColors, MirasTextStyles, spacing), ThemeData
    router/                go_router configuration
    db/                    Drift database definitions, connection setup
    l10n/                  ARB files (fa), generated localizations
    audio/                 audio playback service (just_audio wrapper)
    persian_text/          Persian digit formatting, text utilities
    widgets/               design-system components (MirasButton, CoupletView, …)
  features/
    onboarding/
    home_path/             chapter map / learning path
    lesson/                lesson runner + all exercise widgets
    review/                SRS review deck
    gamification/          XP, streak, hearts, achievements (engine + UI chips)
    library/               free reading of verses/retellings
    profile/               stats, achievements, settings
```

Each feature: `presentation/` (widgets/screens) → `application/` (Riverpod
notifiers/controllers) → `domain/` (entities + pure logic) ← `data/` (repositories).

**Dependency rules (enforced by review + lint):**
- `domain` is pure Dart: no Flutter, no Drift, no Riverpod. This keeps the core
  logic (FSRS, gamification rules) trivially unit-testable and portable.
- Features do not import each other's internals; cross-feature needs go through
  domain interfaces or core.
- Widgets never touch databases; only repositories do.

## 4. Key technology choices (each has an ADR)

| Concern | Choice | ADR |
|---|---|---|
| Framework | Flutter (stable channel) | [0001](adr/0001-flutter-for-cross-platform-client.md) |
| Data strategy | Local-first + static-CDN content packs | [0002](adr/0002-local-first-with-content-packs.md) |
| State management / DI | Riverpod | [0003](adr/0003-riverpod-for-state-management.md) |
| Persistence | Drift (SQLite), split content/user DBs | [0004](adr/0004-drift-with-split-databases.md) |
| Audio | Pre-baked TTS in content packs | [0005](adr/0005-prebaked-tts-audio.md) |
| Spaced repetition | FSRS | [0006](adr/0006-fsrs-for-spaced-repetition.md) |
| Navigation | go_router (declarative, deep-link ready for web phase) | — |
| Lints | very_good_analysis | — |

## 5. Content pipeline

1. **Source:** Shahnameh text from the public-domain Ganjoor corpus; meanings,
   interpretations, retellings, vocabulary notes, and exercises are authored for
   this project in `content/` as YAML (human-editable, git-reviewed like code).
2. **Compile:** `dart run content_compiler build` —
   validates every file against the schema (unknown fields, missing refs, broken
   verse/vocab links are build errors); normalizes Persian text (Arabic ي/ك →
   Persian ی/ک, ZWNJ consistency); generates TTS audio for vocab and verses via a
   provider adapter (Azure `fa-IR` neural voices initially), cached by content hash
   so unchanged text never re-generates; writes a **content pack**: one SQLite file
   + asset directory, stamped with `(pack_version, schema_version, checksum)`.
3. **Ship:** MVP bundles the pack in app assets. The pack format is
   location-independent: later the same artifact is uploaded to object storage/CDN
   and fetched by the app (`ContentRepository` already abstracts the source).
4. **Runtime:** the app opens the pack read-only. Pack updates (post-MVP) are
   downloaded, checksum-verified, and swapped atomically; user progress references
   content by stable IDs, which are **immutable across pack versions**.

Content IDs are human-readable and stable, e.g. `zahhak`, `zahhak.l03`,
`zahhak.v012`, `vocab.kherad` — renames are forbidden; deprecation is additive.

## 6. Localization

UI strings live in ARB (`fa` only for now) with generated accessors — no hardcoded
user-facing strings (enforced in review; lint rule where possible). All numerals pass
through `PersianNumberFormatter`. The app forces `Locale('fa')` and RTL
directionality; adding locales later is additive.

## 7. Error handling & observability

- Domain operations return typed results (`Result<T, DomainFailure>`; no throwing
  across layer boundaries).
- Structured logging behind a `Logger` facade; debug builds log verbosely, release
  builds log warnings+. No PII by design (there is none).
- Crash reporting deferred until beta distribution (decision in M5; candidates:
  Sentry, Crashlytics — evaluated against the no-personal-data stance).

## 8. Testing strategy

| Layer | Tests | Gate |
|---|---|---|
| Domain (FSRS, XP, streak, hearts) | Exhaustive unit tests, property-style where useful | 100% of rule branches |
| Content compiler | Unit + fixture tests (valid/invalid content) | All exercise schemas covered |
| Design-system components | **Golden tests in `fa`/RTL** — the enforcement mechanism for typography/RTL correctness | Every core component; light + dark |
| Exercise widgets & lesson runner | Widget tests (interaction → state) | Every exercise type |
| End-to-end | Integration test: complete a lesson, verify progress/XP/hearts persisted | Critical path |

**CI (GitHub Actions), on every PR:** `flutter analyze` (zero issues) → `dart format
--set-exit-if-changed` → all tests including goldens → content compiler validation of
`content/`. Golden updates require an intentional, reviewed diff.

## 9. Future-proofing (phases 1.5–3)

- **Backend seam:** repositories are interfaces; a sync engine (e.g., Supabase or
  custom) implements them additively. User store schema includes `updated_at` on
  mutable tables from day one to make sync tractable. Leagues attach to the existing
  XP event stream.
- **Web (phase 2):** Drift runs on web via WASM SQLite; go_router gives URL routing;
  canvas rendering acceptable for the app-like experience. Public marketing pages, if
  any, are plain HTML — not Flutter web.
- **iOS (phase 3):** no architectural work expected beyond platform setup and
  store assets.
