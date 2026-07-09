import 'package:flutter_test/flutter_test.dart';

import 'package:miras/features/profile/domain/beta_metrics.dart';

void main() {
  group('weekStart', () {
    test('maps every weekday to the preceding (or same) Saturday', () {
      // 2026-07-04 is a Saturday.
      final saturday = DateTime(2026, 7, 4);
      final expectations =
          {
            DateTime(2026, 7, 4): saturday, // شنبه itself
            DateTime(2026, 7, 5): saturday, // Sunday
            DateTime(2026, 7, 6): saturday, // Monday
            DateTime(2026, 7, 7): saturday, // Tuesday
            DateTime(2026, 7, 8): saturday, // Wednesday
            DateTime(2026, 7, 9): saturday, // Thursday
            DateTime(2026, 7, 10): saturday, // Friday (آدینه, week's last day)
            DateTime(2026, 7, 11): DateTime(2026, 7, 11), // next Saturday
          }..forEach((day, expected) {
            expect(BetaMetrics.weekStart(day), expected, reason: '$day');
          });
      expect(expectations, isNotEmpty);
    });

    test('strips the time of day', () {
      expect(
        BetaMetrics.weekStart(DateTime(2026, 7, 9, 23, 59)),
        DateTime(2026, 7, 4),
      );
    });
  });

  group('compute', () {
    final now = DateTime(2026, 7, 9, 20);
    final installedAt = DateTime(2026, 6, 20, 10);

    BetaMetricsReport report({
      DateTime? activatedAt,
      List<AttemptSample> attempts = const [],
      int longestStreak = 0,
      int weeks = 4,
    }) => BetaMetrics.compute(
      now: now,
      installedAt: installedAt,
      activatedAt: activatedAt,
      lessonsCompleted: activatedAt == null ? 0 : 3,
      effectiveStreak: 2,
      longestStreak: longestStreak,
      attempts: attempts,
      weeks: weeks,
    );

    test('pre-activation report is honest about it', () {
      final r = report();
      expect(r.activated, isFalse);
      expect(r.daysToActivation, isNull);
      expect(r.toJson()['activated_at'], isNull);
    });

    test('activation captures days from install', () {
      final r = report(activatedAt: DateTime(2026, 6, 22, 10));
      expect(r.activated, isTrue);
      expect(r.daysToActivation, 2);
    });

    test('seven-day retention proxy follows the longest streak', () {
      expect(report(longestStreak: 6).sevenDayStreakReached, isFalse);
      expect(report(longestStreak: 7).sevenDayStreakReached, isTrue);
    });

    test('buckets attempts into Saturday-start weeks, oldest first', () {
      final r = report(
        attempts: [
          // Current week (starts Sat 2026-07-04): 2 of 3 correct.
          (at: DateTime(2026, 7, 5, 9), correct: true),
          (at: DateTime(2026, 7, 9, 18), correct: true),
          (at: DateTime(2026, 7, 9, 19), correct: false),
          // Previous week (starts 2026-06-27): 1 of 1.
          (at: DateTime(2026, 6, 28), correct: true),
        ],
      );

      expect(r.weeklyAccuracy, hasLength(4));
      expect(r.weeklyAccuracy.first.weekStart, DateTime(2026, 6, 13));
      expect(r.weeklyAccuracy.last.weekStart, DateTime(2026, 7, 4));

      final current = r.weeklyAccuracy.last;
      expect((current.attempts, current.correct), (3, 2));
      expect(current.accuracy, closeTo(2 / 3, 1e-9));

      final previous = r.weeklyAccuracy[2];
      expect((previous.attempts, previous.correct), (1, 1));
    });

    test('zero-attempt weeks stay in the trend with zero accuracy', () {
      final r = report(attempts: [(at: now, correct: true)]);
      expect(r.weeklyAccuracy.first.attempts, 0);
      expect(r.weeklyAccuracy.first.accuracy, 0);
    });

    test('attempts older than the window count in totals, not the trend', () {
      final r = report(
        weeks: 1,
        attempts: [
          (at: DateTime(2026, 5), correct: false), // ancient
          (at: now, correct: true),
        ],
      );
      expect(r.totalAttempts, 2);
      expect(r.totalCorrect, 1);
      expect(r.weeklyAccuracy.single.attempts, 1);
    });

    test('json shape is stable and schema-versioned', () {
      final json = report(
        activatedAt: DateTime(2026, 6, 22),
        attempts: [(at: now, correct: true)],
        longestStreak: 8,
      ).toJson();

      expect(json['schema'], 1);
      expect(json['seven_day_streak_reached'], true);
      expect(json['lessons_completed'], 3);
      expect(json['effective_streak'], 2);
      final weekly = json['weekly_accuracy']! as List<Object?>;
      expect(weekly, hasLength(4));
      final last = weekly.last! as Map<String, Object?>;
      expect(last['week_start'], '2026-07-04');
      expect(last['accuracy'], 1.0);
    });
  });
}
