# Performance measurement (M8)

Budgets are pass/fail gates from docs/ROADMAP.md M8, measured on named real
devices — release (or profile) builds only; debug numbers are meaningless.

| Metric | Budget | How to measure |
|---|---|---|
| Cold start (TTID) | < 2000 ms, median of 5 | `tool/perf/coldstart.sh [device]` against an installed release build |
| Fully drawn | < 2500 ms | DevTools timeline; bootstrap phases are tagged `miras.bootstrap.*` |
| Jank | ≥ 99% of frames ≤ 16.7 ms (build+raster); zero frames > 100 ms post-launch | perf session below |
| Lesson transition | ≤ 1 dropped frame per exercise→exercise transition | perf session below (tagged windows) |
| APK size | ≤ 40 MB universal — **known to fail (~66 MB); D12 revisit due in M8** | `ls -l` after `flutter build apk --release` |

## The scripted perf session

Drives onboarding → the full first lesson → home-path scrolling while
collecting real `FrameTiming`s, then emits a budget report
(`core/perf/frame_report.dart` holds the math and the budget constants):

```sh
cd app
flutter drive --profile -d <device-id> \
  --driver=test_driver/integration_test.dart \
  -t integration_test/perf_session_test.dart
```

The JSON report lands in `app/build/integration_response_data.json` (and is
printed as a `PERF_REPORT {...}` line). **The session wipes the device's user
store** (it starts from fresh install) — use a test device.

By default the run *measures* and always passes; add
`--dart-define=PERF_STRICT=true` to make budget misses fail the run (the M8
gate mode).

## Per-release regression tracking

Copy the report to `docs/perf/reports/v<X.Y.Z>-<device>.json` and commit it
alongside the release. Comparing `p90_us` / `smooth_ratio` across releases is
the cheap early-warning signal; a budget flip is a release blocker once M8
lands.
