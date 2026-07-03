# Product Requirements Document — Miras (میراث), Phase 1

| | |
|---|---|
| **Product** | Miras (میراث) — gamified learning app for Persian classical literature |
| **Phase** | 1 — Android MVP |
| **Status** | Approved scope, in development |
| **Last updated** | 2026-07-03 |

## 1. Vision

Make Persian classical literature — starting with Ferdowsi's Shahnameh — as approachable
and habit-forming as learning a language on Duolingo. Users spend 5–15 minutes a day and
come away actually able to *read and understand* the original verses, not just summaries.

## 2. Problem

The Shahnameh is culturally central but practically inaccessible: archaic vocabulary,
unfamiliar grammar, and 50,000 couplets of intimidating length. Existing resources are
either academic (commentaries, print editions) or passive (audiobooks, retellings).
Nothing teaches *active reading skill* incrementally, with feedback and retention
mechanics. The success of language-learning apps proves the model; no one has applied
it seriously to Persian literary heritage.

## 3. Target users

| Persona | Description | Primary need |
|---|---|---|
| **The intimidated enthusiast** | Adult Persian speaker (Iran or diaspora) who loves the *idea* of the Shahnameh but bounced off the text | Low-friction entry; confidence-building |
| **The student** | High-school / university student who must study classical texts | Vocabulary + verse comprehension that sticks (SRS) |
| **The heritage learner** | Diaspora Persian speaker, fluent orally, weaker literacy | Reading practice with audio support |

All personas are Persian speakers. Phase 1 does **not** target non-Persian speakers
(no translation UI) — that is a possible later product direction, not MVP.

## 4. Product principles

1. **The text is the hero.** Verses are displayed beautifully and treated with respect;
   gamification serves comprehension, never distracts from it.
2. **Never punish curiosity.** Reading verses, meanings, and retellings costs nothing;
   hearts are only at stake in exercises.
3. **Small, complete sessions.** Every lesson is finishable in ≈3–5 minutes and ends
   with a sense of progress.
4. **Earned ornament.** Persian visual identity appears at moments of meaning
   (chapter covers, celebrations) — the working UI stays calm and minimal.

## 5. Phase 1 scope

### 5.1 Content

Four stories from the Shahnameh, in narrative order, ~6–8 lessons each (~28 lessons):

1. **پادشاهی جمشید** — Jamshid's reign, glory, and hubris
2. **ضحاک و کاوهٔ آهنگر** — Zahhak, the serpent king, and Kaveh's uprising
3. **فریدون** — Fereydun's victory and the division of the world
4. **رستم و سهراب** — the marquee tragedy

Each story (Chapter) follows a five-part lesson arc:

| # | Lesson type | Content |
|---|---|---|
| 1 | Vocabulary (واژگان) | Difficult/archaic words: meaning, pronunciation audio, etymology note |
| 2 | Practice (تمرین) | Matching, multiple choice, cloze, listening exercises on that vocabulary |
| 3 | Verses (ابیات) | Selected couplets with modern-Persian meaning and interpretation |
| 4 | Story (داستان) | Simplified prose retelling with illustrations, checked by comprehension questions |
| 5 | Review (مرور) | Mixed exercises: comprehension, event sequencing, verse reassembly |

Longer stories repeat the arc across multiple "acts."

### 5.2 Exercise types (8)

| Type | Interaction | Skill |
|---|---|---|
| Vocab intro card | Tap-through presentation (word, meaning, audio, etymology) | Introduction |
| Matching | Match word ↔ meaning pairs | Vocabulary |
| Multiple choice | Pick correct meaning/answer from 4 | Vocabulary / comprehension |
| Cloze | Fill the blanked word in a hemistich (word bank) | Verse reading |
| Listening | Hear audio → select or assemble the text | Listening |
| Hemistich assembly | Arrange shuffled word tiles into the correct مصراع | Verse structure |
| Comprehension MCQ | Question about story events/meaning | Comprehension |
| Event sequencing | Order story events chronologically | Comprehension |

### 5.3 Gamification

| Mechanic | Phase 1 behavior |
|---|---|
| **XP** | Earned per completed lesson with accuracy bonus; daily XP goal selectable |
| **Streak** | A day counts if ≥1 lesson or review session is completed; streak-freeze items; milestone celebrations |
| **Hearts** | 5 max; −1 per wrong answer in lessons; timed refill; instant refill by completing an SRS review session (reinforces the learning loop) |
| **Achievements** | Badges for milestones (first chapter, 7-day streak, perfect lesson, vocab counts, …) |
| **Daily recap** | Local notification (opt-in) with streak status and due reviews |
| **Spaced repetition** | FSRS-scheduled review deck of encountered vocabulary; dedicated review tab |

**Explicitly deferred (require accounts/backend):** leagues/leaderboards, friends,
cross-device sync. The gamification engine is designed so these attach later without
rework (see ARCHITECTURE.md).

### 5.4 App surface (screens)

Onboarding (brief, sets daily goal + notification opt-in) · Home/learning path
(chapter map) · Lesson runner · Lesson results · Review tab (SRS) · Chapter library
(read verses/retellings freely) · Profile (stats, achievements, streak calendar) ·
Settings.

## 6. Non-functional requirements

- **Offline-first:** every feature works with no connectivity.
- **Persian/RTL correctness:** full RTL layout; correct rendering of Persian script
  including ZWNJ; Persian digits throughout; verse-grade typography. Enforced by
  golden tests in CI (hard requirement, not best-effort).
- **Performance:** 60fps minimum (120 where hardware allows); cold start < 2s on a
  mid-range Android device; lesson transitions instant.
- **Accessibility:** TalkBack labels on all interactive elements; honors system font
  scaling; touch targets ≥ 48dp; WCAG AA contrast.
- **Quality bar:** visual and interaction polish comparable to top-tier consumer apps.
  This is an explicit acceptance criterion for every milestone, not a final pass.
- **Privacy:** no accounts, no personal data collection in phase 1; analytics (if any)
  local-only in MVP.

## 7. Success metrics (beta)

- **Activation:** ≥70% of installers complete lesson 1.
- **Retention proxy:** ≥30% of week-1 users maintain a 7-day streak.
- **Learning:** SRS review accuracy trends upward per user cohort.
- **Qualitative:** beta users describe the app as "polished / beautiful" unprompted;
  zero reported Persian-rendering or RTL defects.

## 8. Out of scope for Phase 1

Leagues & social features · accounts/sync · non-Persian UI · other works (Hafez,
Saadi, …) · human-narrated audio (TTS placeholder ships first) · iOS & web builds
(architecture accounts for them; they ship in later phases) · monetization.

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| TTS quality poor on classical verse | TTS is authoring-time and pack-based → swap to human narration later with zero app changes; verse audio can be de-emphasized in UI until then |
| Content authoring is the real bottleneck | Content pipeline (M1) built before lesson engine scales; authoring format optimized for humans; one story fully authored early to validate effort |
| RTL/typography defects in third-party packages | Minimal dependency surface; golden tests catch regressions; wrappers around any package that touches layout |
| Scope creep vs. polish budget | Milestone exit criteria include polish review; features cut before polish is |
