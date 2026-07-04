import 'package:flutter/foundation.dart';

/// Streak state (docs/DATA_MODEL.md §2). Dates are LOCAL calendar days —
/// the whole point of a streak is "did you practice today by your clock".
@immutable
class StreakState {
  const StreakState({
    required this.current,
    required this.longest,
    this.lastActiveDate,
    this.freezesAvailable = 0,
  });

  static const initial = StreakState(current: 0, longest: 0);

  final int current;
  final int longest;

  /// Local calendar date (time-of-day zeroed) of the last counted activity.
  final DateTime? lastActiveDate;
  final int freezesAvailable;
}

/// Pure streak rules: register activity days, earn freezes at milestones,
/// auto-consume freezes for missed days (docs/DATA_MODEL.md §4).
abstract final class StreakEngine {
  /// Streak lengths that award a freeze (then every [repeatMilestone] after).
  static const freezeMilestones = [7, 30];
  static const repeatMilestone = 30;
  static const maxFreezes = 2;

  static DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Registers activity at local time [now].
  static StreakState registerActivity(StreakState s, DateTime now) {
    final today = dateOnly(now);
    final last = s.lastActiveDate;

    if (last != null && !today.isAfter(last)) {
      return s; // Already counted today (or clock went backwards — ignore).
    }

    int current;
    var freezes = s.freezesAvailable;
    if (last == null) {
      current = 1;
    } else {
      final gap = today.difference(last).inDays; // 1 = consecutive day
      final missed = gap - 1;
      if (missed == 0) {
        current = s.current + 1;
      } else if (missed <= freezes) {
        // Freezes silently cover the missed days; the streak continues.
        freezes -= missed;
        current = s.current + 1;
      } else {
        current = 1; // Streak broken.
      }
    }

    if (_earnsFreeze(current) && freezes < maxFreezes) {
      freezes++;
    }

    return StreakState(
      current: current,
      longest: current > s.longest ? current : s.longest,
      lastActiveDate: today,
      freezesAvailable: freezes,
    );
  }

  /// The streak shown to the user right now: today's or yesterday's streak
  /// still counts; older than that displays as broken (0) even before the
  /// next activity is registered.
  static int effectiveCurrent(StreakState s, DateTime now) {
    final last = s.lastActiveDate;
    if (last == null) return 0;
    final daysSince = dateOnly(now).difference(last).inDays;
    if (daysSince <= 1) return s.current;
    if (daysSince - 1 <= s.freezesAvailable) return s.current;
    return 0;
  }

  static bool _earnsFreeze(int current) =>
      freezeMilestones.contains(current) ||
      (current > repeatMilestone && current % repeatMilestone == 0);
}
