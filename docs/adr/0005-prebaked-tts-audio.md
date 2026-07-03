# ADR-0005: Pre-baked TTS audio in content packs

**Status:** Accepted (2026-07-03) · approved by project owner

## Context

Listening exercises and pronunciation guidance need Persian audio for vocabulary and
verses. Options: on-device TTS at runtime, cloud TTS at runtime, pre-generated TTS at
authoring time, human narration, or deferring listening features.

## Decision

Generate audio with **neural TTS at content-authoring time** (initially Azure `fa-IR`
neural voices via a provider adapter) and ship the files **inside content packs**.
Cache generations by content hash so unchanged text never re-generates.

## Rationale

- Keeps the app fully offline (no runtime TTS dependency) and audio quality
  consistent across devices (on-device Persian TTS varies wildly).
- Authoring-time generation means the audio source is swappable — better TTS or
  **human narration later requires zero app changes**, only a pack rebuild.
- Human narration now would gate every content release on recording logistics.

## Consequences

- Verse recitation quality will be mediocre (neural TTS doesn't handle classical
  prosody well). Accepted for MVP; the UI de-emphasizes verse audio until narration
  quality improves. Vocabulary pronunciation quality is adequate.
- Content pipeline needs a TTS API key (kept out of the repo; `.env`, CI secret).
- Pack size grows with audio (~monitored in M1; ogg/opus at speech bitrates keeps
  4 stories well within acceptable app size).
