# ADR-0007: Sentry for crash reporting

**Status:** Accepted (2026-07-08)

## Context

Crash reporting was deferred until beta distribution (docs/ARCHITECTURE.md §7),
with Sentry and Firebase Crashlytics as candidates, evaluated against the
project's no-personal-data stance (docs/PRD.md §6, §8) and phase 2's web
target (docs/ARCHITECTURE.md §9).

## Decision

Adopt **Sentry** (`sentry_flutter`) for crash and error reporting.

## Rationale

- PII scrubbing is configurable at the SDK level, matching the
  no-accounts/no-personal-data stance — there is no user data to scrub in
  the first place, but Sentry's default event payload (device info, stack
  traces) needs no additional treatment to stay compliant.
- Has a JS/web SDK alongside the Flutter one, so phase 2 (web,
  docs/ARCHITECTURE.md §9) doesn't need a second crash-reporting tool later.
- Self-hostable or SaaS — doesn't lock the project into a single vendor's
  infrastructure.
- Rejected: **Firebase Crashlytics** — free and tightly integrated with
  Android/Play Console tooling, but requires adding Firebase + Google Play
  Services + `google-services.json`, a new Google-ecosystem dependency this
  project has already had friction with (geo-blocked `dl.google.com`/
  `maven.google.com`, docs/DEVELOPMENT.md). Also Android/iOS-only, no web
  story for phase 2.

## Consequences

- Adds a new third-party dependency (`sentry_flutter`) and an external
  account/dashboard to maintain, beyond the project's otherwise
  minimal-dependency policy (docs/ARCHITECTURE.md §4, §8).
- Requires a DSN (project key) to be configured before release — needs to be
  added to the release checklist (docs/RELEASE.md) and kept out of version
  control the same way `key.properties` is.
- No PII is sent by design, but this should be spot-checked once integrated
  (e.g. via Sentry's own event inspector) rather than assumed correct from
  configuration alone.
