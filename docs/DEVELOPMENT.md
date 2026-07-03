# Development setup

## Prerequisites

- **Flutter** (stable channel) — `brew install --cask flutter`
- **JDK 21** — `brew install --cask temurin@21`
- **Android SDK** — command-line tools + `platform-tools`, `platforms;android-35/36`,
  `build-tools`, `emulator`, and an arm64 system image, installed under
  `~/Library/Android/sdk` (Flutter's default lookup path). Android Studio is
  optional; this project builds and runs from the CLI / VS Code.

Verify with `flutter doctor`.

### Network note: blocked Google endpoints

`dl.google.com` and `maven.google.com` geo-block some regions (including where
this project is developed) — downloads return HTTP 404 for every URL. Workarounds
used by this project:

- **Android SDK packages:** point `sdkmanager` at the Tencent mirror, which
  mirrors the official repository byte-for-byte:

  ```sh
  export SDK_TEST_BASE_URL="https://mirrors.cloud.tencent.com/AndroidSDK/"
  sdkmanager "platform-tools" "platforms;android-36" ...
  ```

- **Gradle/Maven artifacts:** `app/android/settings.gradle.kts` and
  `build.gradle.kts` list the Aliyun mirrors of `google` and `central` *before*
  the official repositories. Environments with direct access (e.g. GitHub CI)
  simply resolve from whichever answers first; no configuration difference is
  needed per environment.

- Flutter's own artifacts come from `storage.googleapis.com`, which is not
  blocked. If it ever is, set `FLUTTER_STORAGE_BASE_URL`.

## Everyday commands (run in `app/`)

```sh
flutter run                        # launch on connected device/emulator
flutter test                       # unit + widget + golden tests
flutter test --update-goldens test/goldens   # regenerate goldens (review diffs!)
flutter analyze                    # zero issues required
dart format lib test               # formatting (CI enforces)
flutter gen-l10n                   # regenerate localizations after ARB edits
```

## Emulator

```sh
avdmanager create avd -n miras -k "system-images;android-35;google_apis;arm64-v8a" -d pixel_7
emulator -avd miras
```

## Quality gates (enforced by CI on every push/PR)

1. `dart format` clean · 2. `flutter analyze` zero issues · 3. all tests green,
including goldens (the RTL/Persian-typography regression net).

Golden files are deliberately committed. Never update them without visually
reviewing the diff; they are the enforcement mechanism for the project's hardest
requirement (see docs/ARCHITECTURE.md §8).

## Conventions

See [CLAUDE.md](../CLAUDE.md) (language rules, RTL rules, commit format) and
[docs/ARCHITECTURE.md](ARCHITECTURE.md) (layering, dependency rules).
