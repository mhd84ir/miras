# ADR-0009: Self-hosted GlitchTip as the crash-report backend

**Status:** Accepted (2026-07-09) · decided by project owner

## Context

ADR-0007 adopted the `sentry_flutter` SDK with sentry.io as the intended
backend, flagging ingest verification as an open action. That verification was
planned as a device spike, but the owner resolved it on first principles:
sentry.io is unreachable from Iranian IPs without a VPN, and the beta audience
is Iranian — crash reports from precisely the users we serve would silently
never arrive, with no way to distinguish "no crashes" from "no connectivity."
Candidates: sentry.io SaaS, GlitchTip's hosted SaaS, self-hosted GlitchTip.

## Decision

Run **self-hosted GlitchTip** on Iran-reachable infrastructure as the crash
backend. The app keeps the `sentry_flutter` SDK and ADR-0007's
privacy-respecting configuration unchanged — GlitchTip implements the Sentry
ingest protocol, so the backend choice is only a DSN.

## Rationale

- Reachability is the whole game: a crash reporter the user base can't reach
  is indistinguishable from having none. Self-hosting on an Iran-reachable
  host makes ingest a property we control, not a sanctions-policy variable.
- Zero app-side migration cost now or later: the DSN is a `--dart-define`
  (per ADR-0007), so swapping backends never touches code.
- Open source (MIT), lightweight (Django + PostgreSQL + Redis via
  docker-compose), and crash data stays on infrastructure the owner controls
  — strictly better privacy posture than any SaaS.
- Rejected: **sentry.io SaaS** — geo-blocked from Iran without a VPN; OFAC
  posture (it hard-blocked Russia in 2024) makes future access strictly less
  likely, not more.
- Rejected: **GlitchTip hosted SaaS** — same reachability-uncertainty class
  from Iranian IPs, plus foreign payment for paid tiers; trades one opaque
  dependency for another.

## Consequences

- The owner now operates a service: a VPS (≥2 GB RAM, Docker), TLS, OS/image
  updates, database backups, and uptime are ongoing responsibilities that
  did not exist under SaaS. Deployment config lives in `deploy/glitchtip/`.
- Hosting provider selection (Iranian VPS for rial billing and in-country
  reachability vs. a European host) is a follow-on owner decision made at
  provisioning time.
- If the server is down, crash events from that window are lost (the SDK
  buffers briefly, not durably) — acceptable for beta scale.
- ADR-0007's no-PII verification step now happens against the GlitchTip
  dashboard instead of sentry.io; the obligation is unchanged.
