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
credentials, handled outside this command, full stop) and never publishes
a GitHub Release or uploads to a store (manual, external, hard-to-reverse
actions — it may only *draft* the `gh release create` command for the owner
to run).

Target version (optional): $ARGUMENTS — if given, propose bumping
`app/pubspec.yaml`'s `version:` to this. If not given, read the current
version and propose only incrementing the build number (`+N`) by one,
which docs/RELEASE.md says happens for every published build — ask before
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
     the resulting APK will be debug-signed — expected/fine for a local dry
     run, wrong for anything published.
   - Whether `content/audio_cache/ADAPTER` exists (the committed audio
     cache). If not, the `--tts cache` build below will fail — report it,
     don't work around it.
   - Whether `SENTRY_DSN` is set in the environment. Until the M7 crash
     wiring lands this is informational; after it lands, an unset DSN means
     the release ships without crash reporting — flag it as a checklist
     failure per docs/RELEASE.md, not a nice-to-have.
   - Whether a physical device is attached (`adb devices`) — the E2E step
     below needs one; if none, that step gets reported as "not run,
     manual", never skipped silently.

2. **Propose the version bump**, show the diff, and only apply it to
   `app/pubspec.yaml` after explicit confirmation.

3. **Run the build/verify chain from docs/RELEASE.md, in order, stopping
   immediately if any step fails** (mirror CI's own gating — don't paper over
   a failure and continue):
   ```
   cd tool/content_compiler && dart run content_compiler build --tts cache --strict --content ../../content --out ../../app/assets/content
   cd ../../app
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   flutter test
   flutter analyze
   ```
   Then, if a device is attached, the E2E critical path (this wipes the
   device's user store — confirm with the owner first if the attached
   device is their daily one with real progress):
   ```
   flutter test integration_test -d <device-id>
   ```
   If a step fails, stop, report exactly what failed and where, and don't
   attempt the remaining steps or the APK build.

4. **Build the release APK** (a local, reversible build artifact — safe
   to run regardless of signing status):
   ```
   flutter build apk --release --dart-define=SENTRY_DSN=$SENTRY_DSN
   ```
   Report the output path (`build/app/outputs/flutter-apk/app-release.apk`),
   its size, and its `shasum -a 256`.

5. **Offer to draft Persian release notes.** Look at
   `git log --oneline` since the last release tag (fall back to a sensible
   recent range if none and say so) and propose short, plain-Persian release
   notes summarizing user-facing changes only (skip internal
   refactors/chores/docs) — clearly labeled as a draft for the owner to edit.
   Don't write this to any file unless asked; just present it.

6. **Draft (never run) the publish command** with the real paths and the
   proposed tag, for the owner to execute:
   ```
   gh release create v<X.Y.Z> <apk> <apk>.sha256 --title "میراث <X.Y.Z>" --notes-file <notes>
   ```

7. **Finish with the docs/RELEASE.md checklist itself**, marking each item
   done/not-done based on what this command actually verified:
   - [ ] `--tts cache --strict` content build clean — done if step 3 passed
   - [ ] full test suite green — done if step 3 passed
   - [ ] E2E on device — done only if it actually ran and passed
   - [ ] version bumped — done if step 2 was applied
   - [ ] SENTRY_DSN passed — per the precondition check
   - [ ] release notes (fa) written — draft offered, not "written" until the
     owner reviews it
   - [ ] APK + sha256 attached to the GitHub Release — manual (step 6 drafts
     the command)
   - [ ] smoke test on a real device — always manual, never claim this
