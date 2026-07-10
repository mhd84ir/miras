# ADR-0010: Content-pack update protocol — signed manifest, version-checked bootstrap

**Status:** Accepted (2026-07-09) · scope approved in the M6+ plan

## Context

ADR-0002 promises content-pack updates independent of app releases but
deferred the delivery mechanism. Groundwork is due now: the pack checksum
covers text only (docs/DATA_MODEL.md claims "pack + assets" — since M6 the
audio bytes are invisible to it), the app byte-compares the bundled pack on
every launch instead of reading `pack_version`, and nothing establishes
authenticity for a future CDN-served pack. Candidates: full downloader now,
protocol groundwork now with the downloader deferred, or staying APK-only.

## Decision

Ship the **protocol groundwork** now; defer the downloader until content
updates actually outpace app releases:

- The compiler's pack checksum covers **text + asset bytes**.
- Every build emits `manifest.json` — `pack_version`, `schema_version`,
  per-file sha256 + size (DB and audio), `built_at` — plus a tiny
  `pack_meta.json` sidecar (version + checksum) bundled with the app.
- Releases sign the manifest with an **ed25519 detached signature** via an
  openssl script (`tool/release/`); the private key lives with the owner,
  never in the repo or CI.
- The app's bootstrap compares `(pack_version, checksum)` from the sidecar
  against the installed pack instead of byte-comparing the whole DB — the
  exact seam where "downloaded pack wins when newer" plugs in later.

## Rationale

- A CDN-served pack without authenticity is a content-injection vector into
  a reading app; signing must exist before the first downloaded byte, and
  designing it now costs little.
- Version-checked bootstrap is protocol-correct (byte-compare can't express
  "installed pack is newer than bundled"), reads ~100 bytes instead of the
  whole bundled DB each launch, and isolates the future downloader to one
  seam.
- openssl-based signing keeps the compiler and CI dependency-free (no Dart
  crypto package, no key material in CI); the app needs verification code
  only when the downloader ships.
- Rejected: **full downloader now** — no demand yet (content and app still
  release together); ADR-0002 explicitly deferred it.
- Rejected: **unsigned manifest** — checksum gives integrity, not
  authenticity; retrofitting signatures after packs are in the wild is a
  trust-bootstrapping mess.
- Rejected: **staying APK-only** — walks back ADR-0002's core promise and
  couples every content fix to a full release.

## Consequences

- The asset-inclusive checksum changes every pack's checksum once — the next
  install replaces the pack on device (cheap, but a one-time forced copy).
- The owner holds an ed25519 keypair: generating, storing, and never losing
  it becomes a release responsibility; the public key ships in the app when
  the downloader lands.
- CDN host selection (lean: ArvanCloud object storage) and the downloader
  (fetch, verify, atomic swap) remain open, deliberately — revisit when a
  content-only update is actually wanted.
- Until the downloader ships, the manifest/signature are emitted and tested
  but unconsumed — carried weight, accepted to avoid the retrofit.
