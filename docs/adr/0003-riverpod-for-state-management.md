# ADR-0003: Riverpod for state management and DI

**Status:** Accepted (2026-07-03)

## Context

The app needs app-wide reactive state (hearts, streak, XP visible on several screens),
feature-local state machines (lesson runner), and dependency injection for
repositories/services — all highly testable. Main candidates: Riverpod, Bloc,
Provider, vanilla InheritedWidget/ValueNotifier.

## Decision

**Riverpod** (with code generation) as both state management and DI container.

## Rationale

- Compile-safe: providers are top-level declarations, no runtime lookup failures;
  code-gen removes provider boilerplate.
- Unified solution for DI + reactive state; overriding providers makes unit and
  widget tests trivial (fake repositories, frozen clocks).
- Less ceremony than Bloc for equivalent safety; Bloc's event/state classes add
  weight without benefit at this app's scale. Provider is effectively superseded
  by Riverpod. Vanilla approaches don't scale to the cross-cutting gamification state.

## Consequences

- Convention required (enforced in review): notifiers live in `application/` layers,
  widgets consume via `ConsumerWidget`; no business logic in widgets.
- Build_runner code-gen step in the dev loop.
