# Development setup

## Prerequisites

- **Flutter** (stable channel) — `brew install --cask flutter`
- **JDK 21** — `brew install --cask temurin@21`
- **Android SDK** — command-line tools + `platform-tools`, `platforms;android-35/36`,
  `build-tools`, `emulator`, and an arm64 system image, installed under
  `~/Library/Android/sdk` (Flutter's default lookup path). Android Studio is
  optional; this project builds and runs from the CLI / VS Code.

Verify with `flutter doctor`.

### Network note

`dl.google.com` and `maven.google.com` geo-block some regions: every download
returns HTTP 404. If `sdkmanager` or Gradle downloads fail that way, connect
through a VPN and retry — this project intentionally uses only the official
repositories (no third-party mirrors in the build configuration).

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
