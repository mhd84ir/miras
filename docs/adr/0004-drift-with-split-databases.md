# ADR-0004: Drift/SQLite with split content and user databases

**Status:** Accepted (2026-07-03)

## Context

Persistence needs: (a) read-only structured lesson content, queried relationally
(verses ↔ vocabulary joins, ordered lessons), replaceable wholesale on content
updates; (b) mutable user progress with schema migrations over years. Candidates:
Drift (SQLite), raw sqflite, Isar/Hive/ObjectBox, JSON files.

## Decision

**Drift** on SQLite, with **two physically separate databases**: a read-only content
pack DB and a mutable user DB. User data references content by stable string IDs,
never cross-DB foreign keys.

## Rationale

- Drift: type-safe compiled queries, reactive streams (UI updates when progress
  changes), robust migration framework, and **web support via WASM SQLite** (phase 2
  works without a persistence rewrite). NoSQL options are weaker on relational
  queries and web; raw sqflite gives up type safety and doesn't run on web.
- Split DBs make pack replacement atomic and trivially safe (swap a file, user data
  untouched) and enforce the read-only nature of content at the architecture level.
- SQLite as the pack format doubles as the compiler's output format — one artifact
  from authoring to runtime.

## Consequences

- No DB-level referential integrity between user progress and content: integrity is
  by convention (stable immutable content IDs — see DATA_MODEL.md invariants) and
  compiler-verified.
- Drift code-gen joins the build_runner step (shared with Riverpod).
