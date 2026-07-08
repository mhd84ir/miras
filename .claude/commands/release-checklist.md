---
description: Run the automatable steps of docs/RELEASE.md and report what still needs manual action
argument-hint: "[optional: target version, e.g. 0.9.1+3]"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Release checklist

Runs the mechanical parts of docs/RELEASE.md end-to-end and stops cleanly
before anything that's genuinely risky, external, or a judgment call. This
command never touches `app/android/key.properties` or the upload keystore
(docs/RELEASE.md marks that step "owner only" — keystore + passwords are
credentials, handled outside this command, full stop) and never uploads
anything to Play Console (that's a manual, external, hard-to-reverse action).

Target version (optional): $ARGUMENTS — if given, propose bumping
`app/pubspec.yaml`'s `version:` to this. If not given, read the current
version and propose only incrementing the build number (`+N`) by one,
which docs/RELEASE.md says happens "for every Play upload" — ask before
applying either way; don't silently pick a semver bump (X.Y.Z) yourself,
that's the owner's call.

## Steps

0. **Anchor to the repo root before running anything below** —
   `cd "$(git rev-parse --show-toplevel)"`. Every path/command below (the
   `cd tool/content_compiler`, `cd ../../app` chain especially) is written
   relative to repo root; don't assume that's already the shell's cwd,
   especially mid-session after other work has `cd`'d elsewhere (Bash cwd
   persists across calls, and a stray leftover `cd app` breaks this chain
   silently rather than with an obvious error).

1. **Preconditions (read-only, report don't fix):**
   - Current `version:` in `app/pubspec.yaml`.
   - Whether `app/android/key.properties` exists. If not: say plainly that
     the resulting bundle will be debug-signed and Play will reject it —
     that's expected/fine for a local dry run, not an error to fix here.
   - Whether `AZURE_SPEECH_KEY`/`AZURE_SPEECH_REGION` are set. If not: note
     that the content pack will build with null audio and the app will hide
     listening exercises (docs/CONTENT_GUIDE.md) — ask whether that's
     intentional for this release rather than assuming.

2. **Propose the version bump**, show the diff, and only apply it to
   `app/pubspec.yaml` after explicit confirmation.

3. **Run the build/verify chain from docs/RELEASE.md, in order, stopping
   immediately if any step fails** (mirror CI's own gating — don't paper over
   a failure and continue):
   ```
   cd tool/content_compiler && dart run content_compiler build --strict --content ../../content --out ../../app/assets/content
   cd ../../app
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   flutter test
   flutter analyze
   ```
   If a step fails, stop, report exactly what failed and where, and don't
   attempt the remaining steps or the appbundle build.

4. **Build the release bundle** (a local, reversible build artifact — safe
   to run regardless of signing status):
   ```
   flutter build appbundle --release
   ```
   Report the output path (`build/app/outputs/bundle/release/app-release.aab`)
   and its size.

5. **Offer to draft Persian release notes.** Look at
   `git log --oneline` since the last version-bump commit (or last release
   tag, if any exist — none do yet, so fall back to a sensible recent range
   and say so) and propose short, plain-Persian release notes summarizing
   user-facing changes only (skip internal refactors/chores/docs) — clearly
   labeled as a draft for the owner to edit before pasting into Play Console.
   Don't write this to any file unless asked; just present it.

6. **Finish with the docs/RELEASE.md checklist itself**, marking each item
   done/not-done based on what this command actually verified:
   - [ ] `--strict` content build clean — done if step 3 passed
   - [ ] full test suite green — done if step 3 passed
   - [ ] version bumped — done if step 2 was applied
   - [ ] release notes (fa) written — draft offered in step 5, not "written"
     until the owner reviews/edits it
   - [ ] smoke test on a real device — always manual, never claim this
   
   Then the remaining Play Console steps (create/upload release, store
   listing assets, tester rollout) are entirely manual per docs/RELEASE.md —
   list them plainly as next steps, don't imply this command has done them.
