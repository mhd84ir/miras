# Miras (میراث)

**A gamified learning app for Persian classical literature, starting with Ferdowsi's Shahnameh.**

Miras teaches readers to understand the Shahnameh the way Duolingo teaches languages: short daily lessons, spaced-repetition vocabulary review, and a carefully crafted progression through the stories — from Jamshid's hubris to the tragedy of Rostam and Sohrab.

> به نام خداوند جان و خرد / کزین برتر اندیشه برنگذرد

## Status

**Phase 1 (Android) — in development.** See [docs/ROADMAP.md](docs/ROADMAP.md) for milestones.

| Phase | Target | Status |
|---|---|---|
| 1 | Android app (4 stories, core gamification, SRS) | 🚧 In progress |
| 2 | Web app | Planned |
| 3 | iOS / PWA | Planned |

## Key characteristics

- **Persian-first:** the entire UI and all content are in Persian (fa), fully RTL, with correct Persian typography (ZWNJ, Persian digits, verse-grade text rendering).
- **Local-first:** fully offline; progress and gamification live on-device. Content ships as versioned packs, updatable from static storage — no backend in phase 1.
- **Built with Flutter:** one codebase and one design system across Android → Web → iOS. See [ADR-0001](docs/adr/0001-flutter-for-cross-platform-client.md).

## Repository layout

```
app/                    Flutter application
content/                Authored lesson content (YAML source, per story)
tool/content_compiler/  Dart CLI: validates + compiles content into packs
docs/                   PRD, design system, architecture, data model, ADRs
```

## Documentation

- [Product Requirements (PRD)](docs/PRD.md)
- [Design System](docs/DESIGN_SYSTEM.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Data Model](docs/DATA_MODEL.md)
- [Roadmap](docs/ROADMAP.md)
- [Architecture Decision Records](docs/adr/)

## Getting started (development)

Prerequisites: Flutter (stable channel), Android Studio + Android SDK.

```sh
cd app
flutter pub get
flutter run          # requires a connected device or emulator
flutter test         # unit + widget + golden tests
flutter analyze
```

## Conventions

- Code, comments, docs, and commit messages are in **English**; all user-facing strings are in **Persian** and externalized in ARB files — never hardcoded.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/).
- Every PR must pass `flutter analyze`, all tests, and golden (RTL/typography) checks. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#testing-strategy) for the quality gates.

## Content licensing

The Shahnameh text is public domain, sourced from the [Ganjoor](https://ganjoor.net) corpus. Authored explanations, retellings, and exercises are original work of this project.
