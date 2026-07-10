import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/app.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/notifications/notification_service.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/core/share/share_service.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/review/data/srs_repository.dart';

import '../helpers/fakes.dart';

/// Automated slice of the M8 accessibility gate (PRD §6 WCAG-AA): tap-target
/// size, tap-target labeling, and text contrast on every main screen, in the
/// real theme and RTL. The manual TalkBack walk-through complements this on
/// device.
void main() {
  Widget app({String initialLocation = AppRoutes.home}) => ProviderScope(
    overrides: [
      contentRepositoryProvider.overrideWithValue(
        FakeContentRepository(
          chapterList: const [Fixtures.chapter],
          lessonMap: const {'zahak': Fixtures.lessons},
          vocabMap: {Fixtures.vocab.id: Fixtures.vocab},
        ),
      ),
      progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
      gamificationRepositoryProvider.overrideWithValue(
        FakeGamificationRepository(),
      ),
      srsRepositoryProvider.overrideWithValue(FakeSrsRepository()),
      notificationServiceProvider.overrideWithValue(
        const NoopNotificationService(),
      ),
      shareServiceProvider.overrideWithValue(NoopShareService()),
    ],
    child: MirasApp(initialLocation: initialLocation),
  );

  Future<void> expectGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.home,
  }) async {
    await tester.pumpWidget(app(initialLocation: initialLocation));
    await tester.pumpAndSettle();
  }

  testWidgets('home path meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('review screen meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('library meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('profile meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('beta report meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('گزارش بتا'), 200);
    await tester.tap(find.text('گزارش بتا'));
    await tester.pumpAndSettle();
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('onboarding meets the a11y guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, initialLocation: AppRoutes.onboarding);
    await expectGuidelines(tester);
    handle.dispose();
  });
}
