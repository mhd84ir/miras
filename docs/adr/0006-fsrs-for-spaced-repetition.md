# ADR-0006: FSRS algorithm for spaced repetition

**Status:** Accepted (2026-07-03)

## Context

Vocabulary retention is core to the product (PRD §5.3). We need a review scheduler.
Candidates: SM-2 (classic Anki), FSRS (Free Spaced Repetition Scheduler), Leitner
boxes, or an ad-hoc interval table.

## Decision

Implement **FSRS** with published default parameters as a pure-Dart module in the
domain layer.

## Rationale

- FSRS is the current state of the art (adopted as Anki's modern default), measurably
  better retention-per-review than SM-2, with an open specification and reference
  implementations to validate against.
- Its state model (stability, difficulty, due date) is compact and fits our
  `srs_cards` table cleanly.
- Pure-Dart domain implementation keeps it exhaustively unit-testable (validated
  against reference-implementation test vectors) and portable to future platforms.

## Consequences

- Slightly more implementation effort than SM-2 (bounded; the algorithm is small).
- Per-user parameter optimization (FSRS's advanced feature) is explicitly out of
  scope for MVP; defaults are used. The door stays open since review history is
  retained in `exercise_attempts`.
