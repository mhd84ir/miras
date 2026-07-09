# Audio cache (committed)

Pre-baked pronunciation audio (ADR-0005 / ADR-0008), keyed by
`sha256(adapter_id + text)` so changed text or a changed voice regenerates
exactly what it invalidates. The `ADAPTER` marker records which backend/voice
produced the cache.

This directory is **committed** so that CI and any contributor build
audio-complete packs deterministically, with no TTS toolchain installed:

```sh
dart run content_compiler build --tts cache --strict
```

Regenerating (authoring machine only; needs `piper` + `ffmpeg` on PATH):

```sh
dart run content_compiler build --tts piper --piper-model <voice.onnx>
```

Do not hand-edit files here; they are derived from `content/` text.
