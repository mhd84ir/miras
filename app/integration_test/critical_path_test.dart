import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';
import 'package:miras/features/lesson/presentation/lesson_results_view.dart';
import 'package:miras/main.dart' as app;

import 'helpers/app_driver.dart';

/// The ARCHITECTURE §8 critical path, on a real device:
/// fresh install → onboarding → complete the first lesson (with one
/// deliberate wrong answer) → gamification state persisted.
///
/// Run: `flutter test integration_test/critical_path_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final strings = lookupAppLocalizations(const Locale('fa'));

  testWidgets('fresh install through first lesson persists progress', (
    tester,
  ) async {
    await wipeUserStore();
    unawaited(app.main());
    await tester.pumpAndSettle();

    await completeOnboarding(tester, strings);

    // ---- home path → the one unlocked lesson
    expect(find.byType(LessonPathNode), findsWidgets);
    await tester.tap(find.byType(LessonPathNode).first);
    await tester.pumpAndSettle();

    // ---- the lesson, mixed path (one deliberate wrong answer)
    await driveLessonToResults(tester, strings, oneWrongAnswer: true);

    // Completed (one wrong answer cannot fail a lesson with full hearts).
    expect(find.byType(LessonResultsView), findsOneWidget);
    expect(find.text(strings.lessonCompletedTitle), findsOneWidget);

    // ---- persistence: streak recorded, visible from the profile
    await tester.tap(find.text(strings.lessonContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.navProfile));
    await tester.pumpAndSettle();

    expect(find.text(strings.statStreakDays('۱')), findsWidgets);
    // Lesson vocabulary entered the SRS deck (profile shows tracked count).
    expect(find.text('۰'), findsNothing);
  });
}
