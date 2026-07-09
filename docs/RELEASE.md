# Release guide

Beta distribution is **signed universal APKs on GitHub Releases** (owner
decision, 2026-07-09). Store submission (Google Play, Cafe Bazaar, Myket) is
**deferred** — the Play appendix below stays current for the day the deferral
lifts.

## One-time: create the upload keystore (owner only)

```sh
keytool -genkey -v -keystore ~/keystores/miras-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `app/android/key.properties` (gitignored — never commit):

```properties
storeFile=/Users/<you>/keystores/miras-upload.jks
storePassword=<store password>
keyAlias=upload
keyPassword=<key password>
```

Keep the keystore and passwords in a password manager. Losing the upload
key means re-signing pain for sideloading testers (and a Play support
process later).

## Build the release APK (beta channel)

```sh
cd tool/content_compiler
dart run content_compiler build --tts cache --strict --content ../../content --out ../../app/assets/content
cd ../../app
flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
flutter test integration_test -d <device-id>   # E2E critical path, real device
flutter build apk --release \
  --dart-define=SENTRY_DSN=$SENTRY_DSN         # ADR-0007: DSN stays out of VCS
# → build/app/outputs/flutter-apk/app-release.apk
```

`--tts cache` builds the audio-complete pack from the committed cache and
fails if any listening exercise would ship silent. Without `key.properties`
the APK is debug-signed — fine for local verification, wrong for a release.
Until crash reporting lands (M7), the `--dart-define` is a no-op; once it
lands, a release built without it ships with crash reporting disabled —
treat that as a checklist failure.

## Publish to GitHub Releases

```sh
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk > app-release.apk.sha256
gh release create v<X.Y.Z> \
  build/app/outputs/flutter-apk/app-release.apk \
  app-release.apk.sha256 \
  --title "میراث <X.Y.Z>" --notes-file <persian-notes.md>
```

Release notes are Persian, user-facing changes only. Testers sideload the
APK; the `.sha256` lets them verify the download.

## Versioning

`pubspec.yaml` `version: X.Y.Z+N` — bump `N` (versionCode) for every
published build; `X.Y.Z` follows semver (0.9.x = beta, 1.0.0 after beta
feedback). Tag = `vX.Y.Z`.

## Checklist per release

- [ ] `--tts cache --strict` content build clean
- [ ] full test suite green (`analyze` + `test`)
- [ ] E2E integration test green on a real device
- [ ] version bumped, tag matches
- [ ] SENTRY_DSN passed via `--dart-define` (once M7 wiring lands)
- [ ] release notes (fa) written
- [ ] APK + sha256 attached to the GitHub Release
- [ ] smoke test on a real device (notification schedule + one listening
      exercise included)

## Appendix: Play Store internal testing (deferred)

1. Build `flutter build appbundle --release` instead of the APK.
2. Create the app (package `ir.miras`, Persian default language).
3. App content forms: no ads; data collection answers change once crash
   reporting ships (crash data, opt-out unavailable → declare it), content
   rating questionnaire.
4. Release → Testing → Internal testing → create release, upload the `.aab`,
   add tester emails, roll out.
5. Store listing needs: 512×512 icon (`app/assets/launcher/icon.png`),
   feature graphic 1024×500, ≥2 screenshots (light + dark).

Cafe Bazaar and Myket requirements get documented here as part of M10.
