# ADR-0001: Flutter for the cross-platform client

**Status:** Accepted (2026-07-03) · approved by project owner

## Context

Phase 1 targets Android; phases 2–3 add web and iOS. Two hard requirements dominate:
(1) flawless Persian text shaping and RTL layout on every platform, and (2) a highly
custom, illustrated UI (tazhib ornament, miniature-style illustration, rich animation)
at top-tier polish. Candidates evaluated: native Android (Kotlin + Jetpack Compose),
Kotlin Multiplatform + Compose Multiplatform, React Native, Flutter.

## Decision

Build the client in **Flutter** (stable channel).

## Rationale

- **Owning the renderer is the property both hard requirements reduce to.** Flutter
  ships its own engine with HarfBuzz shaping: Persian renders identically on every
  Android version, iOS, and web. RTL is core API (`Directionality`,
  `EdgeInsetsDirectional`); ZWNJ and bundled Persian fonts work out of the box.
- Pixel-level custom drawing (`CustomPainter`, shaders) plus first-class Rive/Lottie
  fits the bespoke visual identity.
- One codebase and **one design-system implementation** across all three phases.
- Golden tests allow CI-enforcement of Persian typography/RTL — uniquely valuable here.
- Rejected: **React Native** — weakest RTL story (restart-required `I18nManager`,
  per-platform text rendering inconsistencies) against our hardest requirement.
  **KMP/CMP** — strong runner-up, but Compose for Web (Kotlin/Wasm) is immature and
  phase 2 is web. **Native Android** — phases 2–3 would be full rewrites.

## Consequences

- Web (phase 2) is canvas-rendered: fine for the app-like experience, wrong for
  SEO/content pages — any public marketing site will be plain HTML.
- Dart ecosystem is smaller than JS; third-party packages must be vetted for RTL
  correctness (mitigated by a minimal-dependency policy and golden tests).
- Team skill investment is in Dart/Flutter.
