import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/perf/frame_report.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';
import 'package:miras/main.dart' as app;

import 'helpers/app_driver.dart';

/// M8 frame-budget measurement (docs/ROADMAP.md M8): drives a scripted
/// session — first lesson end-to-end plus home-path scrolling — collecting
/// real `FrameTiming`s, and emits the budget report as JSON.
///
/// Run in profile mode on a real device (debug numbers are meaningless):
///   `flutter drive --profile -d <device> \`
///   `  --driver=test_driver/integration_test.dart \`
///   `  -t integration_test/perf_session_test.dart`
/// The report lands in build/integration_response_data.json and is also
/// printed as a `PERF_REPORT {...}` line. Budgets only *fail* the run when
/// built with `--dart-define=PERF_STRICT=true`; by default this measures.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final strings = lookupAppLocalizations(const Locale('fa'));

  testWidgets('scripted session stays within the M8 frame budgets', (
    tester,
  ) async {
    await wipeUserStore();
    unawaited(app.main());
    await tester.pumpAndSettle();
    await completeOnboarding(tester, strings);

    // Collection starts post-launch — the cold-start budget is measured
    // separately (tool/perf/coldstart.sh), not by this harness.
    final samples = <FrameSample>[];
    final marks = <TransitionMark>[];
    void collector(List<FrameTiming> timings) {
      for (final t in timings) {
        samples.add((
          workUs:
              t.buildDuration.inMicroseconds + t.rasterDuration.inMicroseconds,
          vsyncStartUs: t.timestampInMicroseconds(FramePhase.vsyncStart),
        ));
      }
    }

    binding.addTimingsCallback(collector);

    // ---- first lesson, all-correct (deterministic workload)
    await tester.tap(find.byType(LessonPathNode).first);
    await tester.pumpAndSettle();
    await driveLessonToResults(
      tester,
      strings,
      onTransition: (label) => marks.add((label: label, atUs: Timeline.now)),
    );
    await tester.tap(find.text(strings.lessonContinue));
    await tester.pumpAndSettle();

    // ---- home-path scrolling (list performance)
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 2; i++) {
      await tester.fling(scrollable, const Offset(0, -400), 1500);
      await tester.pumpAndSettle();
      await tester.fling(scrollable, const Offset(0, 400), 1500);
      await tester.pumpAndSettle();
    }

    binding.removeTimingsCallback(collector);

    final report = FramePerfReport.compute(samples, transitions: marks);
    final json = jsonEncode(report.toJson());
    // Machine-readable marker for tooling; reportData reaches the host via
    // the flutter drive harness.
    // ignore: avoid_print
    print('PERF_REPORT $json');
    binding.reportData = {'perf': report.toJson()};

    expect(samples, isNotEmpty, reason: 'no frames collected — broken run');
    const strict = bool.fromEnvironment('PERF_STRICT');
    if (strict) {
      expect(report.allBudgetsMet, isTrue, reason: json);
    }
  });
}
