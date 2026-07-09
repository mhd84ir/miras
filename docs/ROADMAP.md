# Roadmap — Phase 1 (Android MVP)

Milestones are sequential; each ends with a **review checkpoint** with the project
owner before the next begins. Estimates assume focused part-time development and
will be recalibrated after M1 (the first milestone with real content-authoring data).

## M0 — Foundation (~1–2 weeks)

Toolchain (Flutter SDK, Android Studio/SDK) · repo scaffold per ARCHITECTURE.md ·
CI pipeline · design tokens + `ThemeData` + fonts (Vazirmatn, Estedad; verse-face
evaluation) · RTL app shell (`fa` locale, go_router skeleton) · golden-test harness
with first component goldens · Persian number/text utilities.

**Exit criteria:** CI green on PRs; app runs on emulator fully RTL with Persian
rendering verified by goldens; verse font decision made with visual comparison.

## M1 — Content pipeline (~2 weeks)

YAML authoring schema + `CONTENT_GUIDE.md` · compiler CLI (validation, Persian
normalization, pack emission) · TTS adapter with content-hash caching · **story 1
(ضحاک) fully authored** — vocab, verses + meanings, retelling, all lesson exercises.

**Exit criteria:** `content_compiler build` produces a valid pack from real content;
invalid fixtures fail with clear errors; authoring effort per story is measured
(recalibrates M5).

## M2 — Lesson engine (~3 weeks)

Home/learning-path screen (chapter map) · lesson runner (exercise sequencing,
progress, hearts integration) · all 8 exercise widgets · answer feedback +
lesson-results screen · library (free reading) basic version.

**Exit criteria:** complete any ضحاک lesson end-to-end on device with persisted
progress; every exercise type widget-tested + golden-tested.

## M3 — Gamification + SRS (~2 weeks)

XP engine + daily goal · streak engine + freeze · hearts economy · achievements
(initial catalog) · FSRS scheduler + review deck UI · daily recap local notification ·
profile screen with stats.

**Exit criteria:** domain rules 100% branch-covered by unit tests; a multi-day
simulated usage script produces correct streak/XP/SRS states.

## M4 — Polish (~2 weeks)

Chapter cover illustrations + spot illustrations · Rive celebration animations ·
sound design (correct/wrong/complete) · onboarding flow · dark theme · reduce-motion
support · TalkBack + font-scale accessibility pass · performance profiling
(cold start, jank).

**Exit criteria:** side-by-side review against top-tier apps passes the owner's
quality bar; a11y checklist complete; no jank on mid-range device profile.

## M5 — Content complete + beta (~2 weeks)

Stories 2–4 (جمشید، فریدون، رستم و سهراب) authored and compiled · content review
pass (accuracy of meanings/interpretations) · beta hardening (edge cases, error
states, empty states) · Play Store internal testing track release · beta feedback
loop set up.

**Exit criteria:** all 4 stories playable start-to-finish; internal-track build
distributed; PRD §7 success metrics instrumented (locally) for beta evaluation.

## M6 — Audio & listening end-to-end (~2 weeks)

Piper TTS adapter + committed audio cache (ADR-0008) · owner A/B voice pick ·
app playback service (`just_audio`) wiring the listening exercises · sound-effects
scope from M4 delivered, `sound_enabled` toggle wired · listening exercises authored
for the four chapters that lack them · CI builds audio-complete packs (`--tts cache`).

**Exit criteria:** every listening exercise appears and plays on a real device;
owner has approved all generated clips; `--strict` build green; release APK size
delta from audio ≤ 10 MB.

## M7 — Reliability & measurement (~2 weeks)

Crash reporting per ADR-0007 (day-1 spike: verify sentry.io ingest from Iranian
IPs; fallback self-hosted GlitchTip — same SDK) with no-PII verification · local
PRD §7 beta-metrics module + opt-in share-sheet export · `integration_test/`
critical-path E2E on device · dynamic daily-recap notification (streak + due
reviews, PRD §5.3) · beta channel: signed universal APKs on GitHub Releases;
RELEASE.md gains the Sentry-DSN step.

**Exit criteria:** forced test crash visible in dashboard with zero PII; metrics
correct against a seeded fixture DB; E2E green on device; v0.9.x installed from a
GitHub Release on a clean device.

## M8 — Real-device quality pass (~1.5 weeks)

Measured after M6+M7 so budgets reflect the near-final app. Budgets (pass/fail):
cold start TTID < 2000 ms / fully-drawn < 2500 ms (median of 5, release build,
mid-range device); ≥ 99% frames ≤ 16.7 ms over a scripted 5-minute session, zero
frames > 100 ms post-launch; ≤ 1 dropped frame per lesson transition; universal
APK ≤ 40 MB. Plus: haptics service + `haptics_enabled` toggle (first user-DB
migration) · notification matrix (2 devices × 3 days, reboot survival) ·
typography-on-glass checklist (densities × font scales × themes) · automated
a11y guideline tests.

**Exit criteria:** every budget row green on named devices; matrix + typography
checklists complete with zero open defects; per-release perf report committed.

## M9 — Content ops & pack-delivery groundwork (~2 weeks)

Editorial-tag cleanup (content is owner-reviewed) · Iraj consistency audit ·
doc-drift fixes (`zahhak`→`zahak` examples, ADR count, checksum description) ·
pack update protocol ADR + compiler support (signed manifest, asset-inclusive
checksum) with runtime `(pack_version, checksum)` bootstrap check shipped now,
downloader deferred (ADR-0002) · Ganjoor verse-narration importer with attribution
(human narration lands here).

**Exit criteria:** zero editorial tags; grep-verified doc consistency; signed
manifest emitted + tested; verse narration playable for ≥ 1 chapter with visible
attribution and owner sign-off.

## M10 — Release-readiness gate (~1 week)

Full release-checklist run · store assets prepared (not submitted — store release
remains deferred by owner decision) · Cafe Bazaar / Myket requirements documented ·
regression sweep incl. re-measured perf budgets · crash-health gate ≥ 99.5%
crash-free sessions over trailing 14 beta days.

**Exit criteria:** `v1.0.0-rc` tagged on GitHub Releases; submission awaits the
owner lifting the deferral.

## Post-phase-1 (parked)

Leagues + accounts/sync (backend phase) · more stories · web app (phase 2) ·
iOS (phase 3) · additional works (Hafez, Saadi…).
