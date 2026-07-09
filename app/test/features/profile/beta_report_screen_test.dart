import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/share/share_service.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/profile/presentation/beta_report_screen.dart';

import '../../goldens/golden_harness.dart';
import '../../helpers/fakes.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeGamificationRepository gamification;
  late NoopShareService share;

  setUp(() {
    final now = DateTime.now();
    progress = FakeProgressRepository()
      ..firstCompletion = now.subtract(const Duration(days: 3))
      ..attemptLog.addAll([
        (at: now.subtract(const Duration(hours: 2)), correct: true),
        (at: now.subtract(const Duration(hours: 1)), correct: true),
        (at: now, correct: false),
      ]);
    gamification = FakeGamificationRepository(now: now)
      ..installed = now.subtract(const Duration(days: 10))
      ..streakState = StreakState(
        current: 3,
        longest: 9,
        lastActiveDate: DateTime(now.year, now.month, now.day),
      );
    share = NoopShareService();
  });

  Widget screen() => ProviderScope(
    overrides: [
      progressRepositoryProvider.overrideWithValue(progress),
      gamificationRepositoryProvider.overrideWithValue(gamification),
      shareServiceProvider.overrideWithValue(share),
    ],
    child: const BetaReportScreen(),
  );

  testWidgets('renders metrics with Persian digits only', (tester) async {
    await pumpGolden(tester, screen());

    expect(find.text('گزارش بتا'), findsOneWidget);
    // 2 of 3 attempts correct → ۶۷٪ از ۳ پاسخ.
    expect(find.textContaining('۶۷٪'), findsWidgets);
    expect(find.textContaining('۳ پاسخ'), findsWidgets);
    // Longest streak 9 ≥ 7 → retention proxy achieved.
    expect(find.text('به دست آمد'), findsOneWidget);

    for (final widget in tester.widgetList<Text>(find.byType(Text))) {
      expect(
        widget.data ?? '',
        isNot(matches(RegExp('[0-9]'))),
        reason: 'ASCII digit leaked into "${widget.data}"',
      );
    }
  });

  testWidgets('share button exports the schema-versioned JSON', (
    tester,
  ) async {
    await pumpGolden(tester, screen());

    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();

    expect(share.shared, hasLength(1));
    final json = jsonDecode(share.shared.single) as Map<String, dynamic>;
    expect(json['schema'], 1);
    expect(json['lessons_completed'], 0);
    expect(json['seven_day_streak_reached'], true);
    expect(json['total_attempts'], 3);
  });
}
