# Miras Design System (نگارین)

The design language for Miras: **minimal canvas, ornamental moments.** The working UI is
calm, modern, and spacious; Persian visual identity — tazhib (illumination) detailing,
miniature-inspired illustration, gold accents — appears at moments of meaning: chapter
covers, celebrations, achievements. Never as decoration-by-default.

## 1. Principles

1. **The text is sacred.** Verses get the best typography in the app: generous size,
   generous line-height, perfect alignment. Nothing competes with them visually.
2. **Calm by default, joyful at milestones.** Exercise screens are distraction-free;
   celebration animations (Rive) are reserved for completion moments so they stay special.
3. **Ornament is earned.** Tazhib patterns and gold appear only on: chapter covers,
   lesson-complete/chapter-complete celebrations, achievement medals, and the app's
   ceremonial surfaces (onboarding). Hard rule: no ornament inside exercise flow.
4. **RTL is the native direction,** not a mirrored afterthought. Every component is
   designed in RTL first.

## 2. Color

Inspired by Persian manuscript art: turquoise faience, lapis lazuli, gold leaf, ivory paper.

### Core palette

| Token | Light | Dark | Usage |
|---|---|---|---|
| `firoozeh` (فیروزه) | `#14A098` | `#2FC4B2` | Primary: buttons, active states, progress |
| `lajvard` (لاجورد) | `#26619C` | `#5B8FCB` | Secondary: links, info, selected chips |
| `zarrin` (زرین) | `#C9A227` | `#D9B44A` | Accent: gold detailing, celebration, achievement |
| `anari` (اناری) | `#B33A3A` | `#D46A6A` | Error, wrong answers, hearts |
| `sabz` (سبز) | `#3B8C5A` | `#5FAE7E` | Success, correct answers |
| `atash` (آتش) | `#E08A2E` | `#E8A455` | Streak flame, warm highlights |

### Surfaces & text

| Token | Light | Dark | Usage |
|---|---|---|---|
| `background` | `#FAF6EE` (ivory paper) | `#0F1826` (night lapis) | App background |
| `surface` | `#FFFFFF` | `#16202F` | Cards, sheets |
| `surfaceVariant` | `#F1EAD9` | `#1D2A3C` | Inset areas, word tiles |
| `ink` | `#1E2630` | `#EDE7DA` | Primary text |
| `inkMuted` | `#5A6472` | `#9AA3B0` | Secondary text |
| `hairline` | `#E4DCC9` | `#273548` | Borders, dividers |

Rules: all pairings must meet WCAG AA (verified in M0 with contrast tooling and
adjusted if needed). Light theme ships first; dark tokens are defined now and ship in M4.
Colors are exposed only through the theme extension (`MirasColors`) — no raw hex in widgets.

## 3. Typography

All faces are open (SIL OFL) and bundled with the app.

| Role | Face | Notes |
|---|---|---|
| UI text | **Vazirmatn** | The modern standard for Persian UI; excellent hinting and Persian glyph coverage |
| Display / headings | **Estedad** | Contemporary Persian display face with character |
| Verse text | **Amiri** | Decided in M0 via on-device comparison against Noto Naskh Arabic and Vazirmatn: classical literary Naskh, clearly distinguishes poetry from UI text |

### Scale (Persian needs taller line-height than Latin: ≥1.6 for body)

| Style | Face / weight | Size / line-height | Usage |
|---|---|---|---|
| `display` | Estedad Bold | 28 / 40 | Chapter titles, celebrations |
| `headline` | Estedad SemiBold | 22 / 32 | Screen titles |
| `title` | Vazirmatn SemiBold | 18 / 28 | Card titles, lesson names |
| `body` | Vazirmatn Regular | 16 / 26 | Default text |
| `bodySmall` | Vazirmatn Regular | 14 / 22 | Secondary text |
| `caption` | Vazirmatn Medium | 12 / 18 | Labels, counters |
| `verse` | Amiri Regular | 22 / 44 | بیت display — the couplet widget (sized up for Amiri's lighter optical weight) |
| `verseMeaning` | Vazirmatn Regular | 15 / 26 | Modern-Persian meaning under verses |

### Persian typography rules (hard requirements)

- **ZWNJ (U+200C, نیم‌فاصله)** is preserved and must render as zero-width: «می‌رود»,
  «کتاب‌ها» — never «می رود» or «میرود». Content is authored with correct ZWNJ.
- **Persian digits (۰–۹)** everywhere in UI via the shared formatter; including
  XP counts, dates, and percentages. Persian decimal separator (٫) where applicable.
- **No fake bold/italic:** only real font weights; italic does not exist for Persian —
  emphasis uses weight or color, never slant.
- **Verse layout:** the couplet widget renders both hemistichs (مصراع) with balanced
  alignment (side-by-side on wide layouts, stacked with clear pairing on narrow),
  never as naive wrapped prose.
- Line breaking must never separate ZWNJ-joined clusters.

## 4. Spacing, shape, elevation

- **Grid:** 4pt base. Named steps: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48`.
  Screen margins 20; card padding 16–20.
- **Radii:** `sm 12 · md 16 · lg 24`; pills for chips/buttons. Soft, contemporary.
- **Elevation:** prefer hairline borders (`hairline` token) and subtle tonal contrast
  over drop shadows. Max one shadow level for floating elements (dialogs, FAB-like).
- **Touch targets:** minimum 48×48dp.

## 5. Motion

| Class | Duration / curve | Usage |
|---|---|---|
| Micro | 120ms, easeOut | Press feedback, toggles |
| Standard | 200–250ms, easeOutCubic | Transitions, reveals, exercise feedback |
| Emphatic | 300–400ms, spring | Correct-answer bounce, progress fill |
| Celebration | Rive animations | Lesson complete, streak milestone, chapter finished |

Rules: motion must never delay input (user can always answer immediately); all standard
motion respects the system reduce-motion setting; celebrations are skippable by tap.

## 6. Ornament & illustration

- **Tazhib usage:** corner ornaments and framing rules derived from manuscript
  illumination, drawn as vector (CustomPainter) in `zarrin` on the current surface —
  used ONLY on chapter covers, celebration screens, achievement medals, onboarding.
- **Illustration style:** flat, contemporary interpretation of Persian miniature —
  simplified forms, miniature color palette (from §2), no gradients-by-default,
  consistent stroke weight. One cover illustration per story; small spot illustrations
  in retellings.
- **Iconography:** rounded, 2px-stroke icon set; custom icons for domain concepts
  (streak flame درفش-inspired, hearts, XP gem as turquoise stone).
- **Anti-clutter rule:** any screen may use at most one ornamental element.

## 7. Component inventory (built in M0–M2, all golden-tested in RTL)

| Component | Notes |
|---|---|
| `MirasButton` (primary/secondary/text) | Pill, bold label, pressed depth effect |
| `LessonPathNode` + path | The chapter map: illuminated-manuscript-inspired winding path |
| `ExerciseScaffold` | Progress bar + hearts header, content, action footer |
| `CoupletView` | The verse widget — hemistich pair layout, tap-word for vocab |
| `WordTile` / `ChoiceChip` | Exercise tiles: idle/selected/correct/wrong states |
| `FeedbackBanner` | Bottom sheet on answer: sabz/anari, meaning recap, continue |
| `ProgressBar` | Rounded, animated fill in firoozeh |
| `StatChip` (streak/XP/hearts) | Home header indicators |
| `AchievementMedal` | Circular medal with tazhib ring, zarrin accents |
| `ChapterCover` | Illustrated card with title, ornament frame, progress |

## 8. Accessibility

- WCAG AA contrast for all text; AAA for body where feasible.
- Full TalkBack support: semantic labels in Persian for every interactive element;
  exercise state changes announced.
- Honors system font scale up to 1.3× without layout breakage (golden-tested).
- Color is never the only signal (correct/wrong also differ by icon + text).

## 9. Voice & tone (Persian copy)

- Warm, encouraging, respectful of the material; modern Persian, no artificial
  archaisms in UI copy — the archaic language belongs to the verses.
- Encouragements draw from the epic register sparingly and playfully
  (e.g., achievement copy may echo Shahnameh phrasing).
- Address the user with informal «تو» consistently, matching the friendly-coach persona
  of gamified learning apps (mascot/persona finalized in M4 with illustration direction).
  This is a deliberate, revisitable choice — switching to «شما» later is a copy-only change
  since all strings live in ARB files.
