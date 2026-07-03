# ADR-0002: Local-first with versioned content packs

**Status:** Accepted (2026-07-03) · approved by project owner

## Context

Phase 1 needs lesson content (static, public-domain text + authored material) and
user progress/gamification state. Options: backend from day one, local-first, or a
hybrid with anonymous cloud sync.

## Decision

**Local-first.** All user state lives on-device. Content is compiled offline into
**versioned packs** (SQLite + assets) bundled with the app; the pack format is
location-independent so packs can later be served from static object storage/CDN
without app rework. No servers, no accounts in phase 1.

## Rationale

- Content is static; progress/XP/streaks/hearts/SRS work perfectly on-device.
- Zero infra cost and no auth/privacy surface; fully offline (valuable for the
  target audience); weeks faster to a polished MVP — polish being the top priority.
- Content updates do not require a backend — only static file hosting.

## Consequences

- **Leagues/leaderboards and cross-device sync are deferred** (they genuinely need a
  backend). Mitigations designed in now: repositories are interfaces (sync engine
  implements them later), mutable user tables carry `updated_at` from day one, and
  XP is an append-only event stream that leagues can consume later.
- Uninstalling the app loses progress (acceptable for beta; sync arrives with the
  backend phase).
