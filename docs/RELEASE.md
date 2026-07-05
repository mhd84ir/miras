# Release guide — Play Store internal testing track

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
key means a Play support process to reset it.

## Build the bundle

```sh
cd tool/content_compiler
dart run content_compiler build --strict --content ../../content --out ../../app/assets/content
cd ../../app
flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
flutter test && flutter analyze
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Without `key.properties` the bundle is debug-signed (fine for local
verification, rejected by Play).

## Play Console (internal testing)

1. Create the app (package `ir.miras`, Persian default language).
2. App content forms: no ads, no data collection (local-first — the privacy
   answers are genuinely "none"), content rating questionnaire.
3. Release → Testing → Internal testing → create release, upload the `.aab`,
   add tester emails, roll out.
4. Store listing needs: 512×512 icon (use `app/assets/launcher/icon.png`),
   feature graphic 1024×500, and at least 2 screenshots (grab from a device
   or emulator in light + dark).

## Versioning

`pubspec.yaml` `version: X.Y.Z+N` — bump `N` (versionCode) for every Play
upload; `X.Y.Z` follows semver (0.9.x = beta, 1.0.0 after beta feedback).

## Checklist per release

- [ ] `--strict` content build clean
- [ ] full test suite green
- [ ] version bumped
- [ ] release notes (fa) written
- [ ] smoke test on a real device (notification schedule included)
