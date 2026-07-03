# CLAUDE.md — Project conventions for Miras (میراث)

Gamified Persian-literature learning app (Duolingo-style) teaching Ferdowsi's Shahnameh.
Flutter, local-first, Persian-only UI with full RTL. Phase 1 targets Android.

## Language rules (hard requirements)

- Code, comments, technical docs, commit messages: **English**.
- ALL user-facing text (UI strings, lesson content, errors): **Persian (fa)**, externalized
  in ARB localization files under `app/lib/core/l10n/`. Never hardcode user-facing strings.
- Persian digits (۰–۹) in all user-facing numbers, via the shared formatter in
  `app/lib/core/persian_text/` — never raw `toString()` into UI.

## RTL & Persian typography (hard requirements)

- Only directional layout APIs: `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `start/end` — never `left/right` variants.
- Preserve ZWNJ (U+200C, نیم‌فاصله) in all content handling; text normalization
  (ي→ی, ك→ک) happens ONLY in the content compiler, never at runtime.
- Golden tests enforce RTL layout and Persian rendering; never update golden files
  without visually confirming the diff is intentional.

## Architecture pointers

- Feature-first layout: `app/lib/features/<feature>/{presentation,application,domain,data}`.
  Dependency rule: presentation → application → domain ← data. Domain is pure Dart.
- State/DI: Riverpod. Navigation: go_router. Persistence: Drift (two DBs: read-only
  content pack, mutable user store). Full details in `docs/ARCHITECTURE.md`.
- Content is authored as YAML in `content/`, compiled by `tool/content_compiler` into
  versioned packs. The app never parses YAML at runtime.
- Significant technical decisions get an ADR in `docs/adr/` (see existing ones first).

## Workflow

- Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- Before any commit: `flutter analyze` clean and `flutter test` green (run in `app/`).
- The project owner reviews work at milestone checkpoints (see `docs/ROADMAP.md`);
  pause for review at milestone boundaries rather than pushing ahead.
- Quality bar is explicit: top-tier consumer-app polish. Prefer doing less, better.
