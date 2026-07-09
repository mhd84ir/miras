# ADR-0008: Local Piper TTS for vocabulary audio

**Status:** Accepted (2026-07-09) · approved by project owner

## Context

ADR-0005 pre-bakes TTS audio into packs at authoring time, "initially Azure
`fa-IR` neural voices via a provider adapter." That provider choice never became
runnable: Azure requires an account, a VPN, and a foreign payment card from this
development environment (the same geo-blocking friction that shaped ADR-0007).
Listening exercises stay hidden until vocabulary audio exists. Candidates for the
generation backend: Azure Speech, ElevenLabs, OpenAI TTS, local open-source Piper
with a Persian voice, or human recording now.

## Decision

Generate vocabulary audio with **Piper** (local, open-source neural TTS) using a
community `fa_IR` voice, on the authoring machine. Commit the generated audio
cache (`content/audio_cache/`) so CI and contributors build audio-complete packs
deterministically via a cache-only mode, with no TTS toolchain installed.
ADR-0005's pre-baked, adapter-based design is unchanged; only the backend differs.

## Rationale

- Runs fully offline on the authoring machine: no account, no VPN, no payment,
  no sanctions exposure — generation is guaranteed possible, today and later.
- Quality (MOS ~3.7–3.9 for ManaTTS-derived voices) is adequate for single
  vocabulary words; the adapter seam keeps a future quality upgrade a pack-only
  change, exactly as ADR-0005 intended.
- Zero cost at any volume; content-hash caching still applies.
- Rejected: **Azure Speech** — best fa-IR quality, but account/VPN/foreign-card
  access is unreliable from here; a pipeline that can fail at generation time
  gates content releases.
- Rejected: **ElevenLabs / OpenAI TTS** — same access friction, plus new
  adapters for no structural benefit.
- Rejected: **human recording now** — gates every content release on recording
  logistics (already rejected in ADR-0005); human narration remains the planned
  upgrade path for verse audio specifically.

## Consequences

- Vocabulary pronunciation will sound noticeably less natural than commercial
  neural voices; accepted for beta, revisit against the quality bar before 1.0.
- The authoring machine needs `piper` and `ffmpeg` installed; documented in
  CONTENT_GUIDE, never required in CI (cache-only builds).
- The committed audio cache adds a few MB of binary files to the repo; the
  `ADAPTER` marker ties cache entries to the generating voice, so a voice swap
  regenerates everything and shows up as a reviewable diff.
- Release builds gain a `--strict` failure when any listening exercise's vocab
  lacks audio — silent skipping is no longer possible in release packs.
- The voice model choice within Piper is an editorial call (owner A/B), recorded
  in the cache's `ADAPTER` marker rather than in this ADR.
