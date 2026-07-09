import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';
import 'package:miras/features/lesson/presentation/lesson_results_view.dart';
import 'package:miras/features/lesson/presentation/widgets/option_tiles.dart';
import 'package:miras/main.dart' as app;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The ARCHITECTURE §8 critical path, on a real device:
/// fresh install → onboarding → complete the first lesson (with one
/// deliberate wrong answer) → gamification state persisted.
///
/// Run: `flutter test integration_test -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final strings = lookupAppLocalizations(const Locale('fa'));

  testWidgets('fresh install through first lesson persists progress', (
    tester,
  ) async {
    await _wipeUserStore();
    unawaited(app.main());
    await tester.pumpAndSettle();

    // ---- onboarding (a fresh store always lands here)
    await tester.tap(find.text(strings.lessonContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.lessonContinue));
    await tester.pumpAndSettle();
    // Decline the reminder — an OS permission dialog would hang the run.
    await tester.tap(find.text(strings.onboardNotifSkip));
    await tester.pumpAndSettle();

    // ---- home path → the one unlocked lesson
    expect(find.byType(LessonPathNode), findsWidgets);
    await tester.tap(find.byType(LessonPathNode).first);
    await tester.pumpAndSettle();

    // ---- drive the lesson; exactly one deliberate wrong answer
    var wrongAnswered = false;
    for (var step = 0; step < 120; step++) {
      await tester.pumpAndSettle();
      if (find.byType(LessonResultsView).evaluate().isNotEmpty) break;

      final options = find.byType(OptionTiles);
      final check = find.text(strings.lessonCheck);
      final proceed = find.text(strings.lessonContinue);

      if (check.evaluate().isNotEmpty && options.evaluate().isNotEmpty) {
        // Question phase. Authored content lists the correct option first,
        // so option 1 is a guaranteed wrong answer for the mixed-path case.
        final tiles = tester.widget<OptionTiles>(options.first);
        final index = wrongAnswered ? 0 : 1;
        wrongAnswered = true;
        await tester.tap(find.text(tiles.options[index]).last);
        await tester.pumpAndSettle();
        await tester.tap(check);
      } else if (proceed.evaluate().isNotEmpty) {
        // Presentation exercise or feedback footer.
        await tester.tap(proceed.last);
      }
    }

    // Completed (one wrong answer cannot fail a lesson with full hearts).
    expect(find.byType(LessonResultsView), findsOneWidget);
    expect(find.text(strings.lessonCompletedTitle), findsOneWidget);
    expect(wrongAnswered, isTrue, reason: 'the mixed path was exercised');

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

/// Drift (drift_flutter) stores the user database under the app-support
/// directory; deleting it before boot recreates the fresh-install state.
Future<void> _wipeUserStore() async {
  for (final dir in [
    await getApplicationSupportDirectory(),
    await getApplicationDocumentsDirectory(),
  ]) {
    for (final name in [
      'miras_user',
      'miras_user.sqlite',
      'miras_user.db',
    ]) {
      final file = File(p.join(dir.path, name));
      if (file.existsSync()) file.deleteSync();
    }
  }
}
