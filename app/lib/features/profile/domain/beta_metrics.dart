/// PRD §7 beta metrics, computed locally from the user store. Privacy is
/// structural (PRD §6): this module only distills data that never leaves the
/// device unless the user explicitly shares the report themselves.
library;

/// One logged exercise attempt, as (when, correct).
typedef AttemptSample = ({DateTime at, bool correct});

/// Review accuracy inside one Iranian calendar week (Saturday-start).
class WeeklyAccuracy {
  const WeeklyAccuracy({
    required this.weekStart,
    required this.attempts,
    required this.correct,
  });

  /// Saturday 00:00 local time.
  final DateTime weekStart;
  final int attempts;
  final int correct;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class BetaMetricsReport {
  const BetaMetricsReport({
    required this.generatedAt,
    required this.installedAt,
    required this.activatedAt,
    required this.lessonsCompleted,
    required this.effectiveStreak,
    required this.longestStreak,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.weeklyAccuracy,
  });

  final DateTime generatedAt;
  final DateTime installedAt;

  /// First-ever lesson completion (PRD §7 activation), null before it.
  final DateTime? activatedAt;
  final int lessonsCompleted;
  final int effectiveStreak;
  final int longestStreak;

  /// All-time attempt counts (the weekly trend below is windowed).
  final int totalAttempts;
  final int totalCorrect;

  /// Oldest → newest, contiguous (zero-attempt weeks included so the trend
  /// reads honestly).
  final List<WeeklyAccuracy> weeklyAccuracy;

  bool get activated => activatedAt != null;

  int? get daysToActivation => activatedAt?.difference(installedAt).inDays;

  /// PRD §7 retention proxy: a 7-day streak was reached at some point.
  bool get sevenDayStreakReached => longestStreak >= 7;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'generated_at': generatedAt.toUtc().toIso8601String(),
    'installed_at': installedAt.toUtc().toIso8601String(),
    'activated_at': activatedAt?.toUtc().toIso8601String(),
    'days_to_activation': daysToActivation,
    'lessons_completed': lessonsCompleted,
    'effective_streak': effectiveStreak,
    'longest_streak': longestStreak,
    'seven_day_streak_reached': sevenDayStreakReached,
    'total_attempts': totalAttempts,
    'total_correct': totalCorrect,
    'weekly_accuracy': [
      for (final w in weeklyAccuracy)
        {
          'week_start': _dateOnly(w.weekStart),
          'attempts': w.attempts,
          'correct': w.correct,
          'accuracy': double.parse(w.accuracy.toStringAsFixed(3)),
        },
    ],
  };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

abstract final class BetaMetrics {
  /// Midnight of the Saturday (شنبه) starting the Iranian week containing [d].
  static DateTime weekStart(DateTime d) {
    final daysBack = (d.weekday - DateTime.saturday) % 7;
    return DateTime(d.year, d.month, d.day - daysBack);
  }

  /// Distills raw user-store facts into the report. [effectiveStreak] and
  /// [longestStreak] arrive pre-computed (StreakEngine owns that logic).
  static BetaMetricsReport compute({
    required DateTime now,
    required DateTime installedAt,
    required DateTime? activatedAt,
    required int lessonsCompleted,
    required int effectiveStreak,
    required int longestStreak,
    required List<AttemptSample> attempts,
    int weeks = 8,
  }) {
    assert(weeks > 0, 'trend needs at least one week');

    final currentWeek = weekStart(now);
    final buckets = <DateTime, ({int attempts, int correct})>{
      for (var i = weeks - 1; i >= 0; i--)
        DateTime(currentWeek.year, currentWeek.month, currentWeek.day - 7 * i):
            (attempts: 0, correct: 0),
    };
    for (final attempt in attempts) {
      final week = weekStart(attempt.at);
      final bucket = buckets[week];
      if (bucket == null) continue; // older than the trend window
      buckets[week] = (
        attempts: bucket.attempts + 1,
        correct: bucket.correct + (attempt.correct ? 1 : 0),
      );
    }

    return BetaMetricsReport(
      generatedAt: now,
      installedAt: installedAt,
      activatedAt: activatedAt,
      lessonsCompleted: lessonsCompleted,
      effectiveStreak: effectiveStreak,
      longestStreak: longestStreak,
      totalAttempts: attempts.length,
      totalCorrect: attempts.where((a) => a.correct).length,
      weeklyAccuracy: [
        for (final MapEntry(key: week, value: bucket) in buckets.entries)
          WeeklyAccuracy(
            weekStart: week,
            attempts: bucket.attempts,
            correct: bucket.correct,
          ),
      ],
    );
  }
}
