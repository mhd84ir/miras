---
description: Review golden test image diffs for RTL/Persian-typography regressions before committing
argument-hint: "[optional: substring to filter which changed goldens to review]"
allowed-tools: Bash, Read, Grep, Glob
---

# Review golden diffs

Golden files under `app/test/goldens/goldens/*.png` are this project's actual
enforcement mechanism for its hardest requirement: correct RTL layout and
Persian typography (CLAUDE.md; docs/ARCHITECTURE.md §8). Per
docs/DEVELOPMENT.md, golden files are "deliberately committed. Never update
them without visually reviewing the diff." This command does that review —
but it assists, it doesn't replace the developer actually looking. End by
saying so plainly, not by declaring the diff safe to commit.

Filter (optional): $ARGUMENTS — if non-empty, only review changed goldens
whose filename or owning test name contains this string. If empty, review
everything changed.

## Steps

0. **Anchor to the repo root before running anything below** —
   `cd "$(git rev-parse --show-toplevel)"`. Every path in this command is
   written relative to repo root; don't assume that's already the shell's
   cwd, especially mid-session after other work has `cd`'d elsewhere (Bash
   cwd persists across calls and this has broken this exact command before —
   `app/test/...` silently resolves to `app/app/test/...` if cwd is already
   `app/`).

1. **Find pending golden changes.**
   ```
   git status --porcelain -- app/test/goldens/goldens/
   ```
   If this is empty, ask whether to regenerate first
   (`cd app && flutter test --update-goldens test/goldens`) rather than
   assuming — it's a slow, whole-suite operation, not scoped to whatever the
   developer is actually mid-change on. If still empty after regenerating,
   report "no golden diffs to review" and stop here.

2. **For each changed or newly-added PNG** (filtered by `$ARGUMENTS` if given):
   - Find what produces it: `grep -rn "goldens/<name>.png" app/test/goldens/*_test.dart`,
     then read that `testWidgets` block to know the widget, brightness,
     surface size, and text-scale under test.
   - If it existed before HEAD, pull the old version out for comparison
     (use your scratchpad/temp directory):
     `git show HEAD:app/test/goldens/goldens/<name>.png > <tmp>/<name>_old.png`
     (skip this for newly-added goldens; say so instead).
   - View the new image, and the old one if you extracted it (Read handles
     PNGs directly — actually look, don't infer from the test code alone).
   - Judge the new image against these hard requirements, specifically:
     - **RTL flow** — content runs right-to-left, no stray left-aligned
       artifacts or elements that look mirrored incorrectly.
     - **ZWNJ (نیم‌فاصله)** — joined-but-separate word pairs (e.g. «می‌رود»،
       «داستان‌ها») render visually attached with no incorrect break or gap.
     - **Persian digits** — any visible numerals are ۰–۹, never ASCII 0-9.
     - **General integrity** — no clipped or overflowing text, no obviously
       broken layout for the stated surface size / text scale.
   - Describe what visually changed vs. the old image, in plain terms — not
     just "looks fine," actually say what's different. Don't stop at "the
     images look the same": if dimensions or file size differ at all, check
     with `file <path>` whether the PNG color type changed (e.g. indexed/RGB
     vs RGBA) — an encoder/SDK-version difference can inflate file size with
     zero actual visual change, and that's a real, common case, not a
     hypothetical.
   - Give a verdict: *intentional-looking*, *needs a closer look* (say
     exactly why), *likely a regression* (say exactly what's wrong), or
     *encoding-only diff — no real change* (same dimensions and rendered
     content, only the PNG color-type/compression changed; this happens when
     the local Flutter/Skia version differs from whatever produced the
     committed golden, and it's a reason to discard the regenerated file
     rather than commit it, not a reason to treat the golden as updated).

3. **Cross-check the code, not just the pixels.** Run
   `git diff -- app/lib` and scan touched widget/theme files for any
   newly-introduced non-directional layout API: `EdgeInsets.only(left:`,
   `Alignment.centerLeft`/`centerRight`, `.left`/`.right` on `Positioned`, or
   raw `left`/`right` params anywhere layout is specified. CLAUDE.md requires
   `EdgeInsetsDirectional`/`AlignmentDirectional`/`PositionedDirectional`/
   `start`/`end` exclusively. Flag any hit as a real problem regardless of how
   the golden image itself looks — a directional-API regression can render
   correctly today in the forced `fa`/RTL test harness while silently
   breaking the day an LTR locale is added (see docs/ARCHITECTURE.md §9 on
   the web/later-phases plan).

4. **Finish with a summary table** — golden file | test | verdict | notes —
   followed by an explicit reminder that this is a review aid, not a
   commit-approval mechanism: the developer confirms the diff is intentional
   themselves before committing, per docs/DEVELOPMENT.md.
