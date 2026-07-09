import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/features/lesson/presentation/lesson_results_view.dart';
import 'package:miras/features/lesson/presentation/widgets/option_tiles.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Drift (drift_flutter) stores the user database under the app-support
/// directory; deleting it before boot recreates the fresh-install state.
Future<void> wipeUserStore() async {
  for (final dir in [
    await getApplicationSupportDirectory(),
    await getApplicationDocumentsDirectory(),
  ]) {
    for (final name in ['miras_user', 'miras_user.sqlite', 'miras_user.db']) {
      final file = File(p.join(dir.path, name));
      if (file.existsSync()) file.deleteSync();
    }
  }
}

/// Walks the three onboarding pages, declining the reminder (an OS
/// permission dialog would hang a scripted run).
Future<void> completeOnboarding(
  WidgetTester tester,
  AppLocalizations strings,
) async {
  await tester.tap(find.text(strings.lessonContinue));
  await tester.pumpAndSettle();
  await tester.tap(find.text(strings.lessonContinue));
  await tester.pumpAndSettle();
  await tester.tap(find.text(strings.onboardNotifSkip));
  await tester.pumpAndSettle();
}

/// Drives whatever lesson is on screen to its results view. Authored content
/// lists the correct option first, so option 0 always passes and option 1 is
/// a guaranteed wrong answer when [oneWrongAnswer] asks for a mixed path.
/// [onTransition] fires just before every continue/check tap — perf runs use
/// it to timestamp exercise transitions.
Future<void> driveLessonToResults(
  WidgetTester tester,
  AppLocalizations strings, {
  bool oneWrongAnswer = false,
  void Function(String label)? onTransition,
}) async {
  var wrongPending = oneWrongAnswer;
  for (var step = 0; step < 120; step++) {
    await tester.pumpAndSettle();
    if (find.byType(LessonResultsView).evaluate().isNotEmpty) return;

    final options = find.byType(OptionTiles);
    final check = find.text(strings.lessonCheck);
    final proceed = find.text(strings.lessonContinue);

    if (check.evaluate().isNotEmpty && options.evaluate().isNotEmpty) {
      final tiles = tester.widget<OptionTiles>(options.first);
      final index = wrongPending ? 1 : 0;
      wrongPending = false;
      await tester.tap(find.text(tiles.options[index]).last);
      await tester.pumpAndSettle();
      onTransition?.call('check-$step');
      await tester.tap(check);
    } else if (proceed.evaluate().isNotEmpty) {
      onTransition?.call('continue-$step');
      await tester.tap(proceed.last);
    }
  }
  fail('lesson never reached its results view within the step budget');
}
