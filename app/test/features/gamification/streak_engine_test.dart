import 'package:flutter_test/flutter_test.dart';

import 'package:miras/features/gamification/domain/streak_engine.dart';

void main() {
  DateTime day(int d, [int hour = 12]) => DateTime(2026, 1, d, hour);

  StreakState after(List<int> activeDays, {StreakState? from}) {
    var s = from ?? StreakState.initial;
    for (final d in activeDays) {
      s = StreakEngine.registerActivity(s, day(d));
    }
    return s;
  }

  group('registerActivity', () {
    test('first activity starts a streak of 1', () {
      final s = after([1]);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.lastActiveDate, DateTime(2026)); // 2026-01-01
    });

    test('consecutive days increment', () {
      final s = after([1, 2, 3]);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('same-day repeat activity does not double-count', () {
      var s = after([1, 2]);
      s = StreakEngine.registerActivity(s, day(2, 23));
      expect(s.current, 2);
    });

    test('a missed day without freezes resets to 1', () {
      final s = after([1, 2, 4]);
      expect(s.current, 1);
      expect(s.longest, 2, reason: 'longest survives the reset');
    });

    test('freeze earned at day 7 covers one missed day', () {
      final s = after([1, 2, 3, 4, 5, 6, 7]); // earns 1 freeze at 7
      expect(s.freezesAvailable, 1);

      final resumed = StreakEngine.registerActivity(s, day(9)); // missed 8th
      expect(resumed.current, 8, reason: 'freeze bridges the gap');
      expect(resumed.freezesAvailable, 0);
    });

    test('two missed days with one freeze reset the streak', () {
      final s = after([1, 2, 3, 4, 5, 6, 7]);
      final resumed = StreakEngine.registerActivity(s, day(10)); // missed 8,9
      expect(resumed.current, 1);
      expect(
        resumed.freezesAvailable,
        1,
        reason: 'freeze not wasted on a lost cause',
      );
    });

    test('freezes cap at 2', () {
      var s = StreakState.initial;
      for (var d = 1; d <= 60; d++) {
        s = StreakEngine.registerActivity(s, day(d));
      }
      expect(s.current, 60);
      // Earned at 7, 30, 60 but capped at 2.
      expect(s.freezesAvailable, StreakEngine.maxFreezes);
    });
  });

  group('effectiveCurrent', () {
    test('shows the streak on the same day and the day after', () {
      final s = after([1, 2, 3]);
      expect(StreakEngine.effectiveCurrent(s, day(3, 18)), 3);
      expect(StreakEngine.effectiveCurrent(s, day(4, 8)), 3);
    });

    test('shows 0 once the streak is unrecoverable', () {
      final s = after([1, 2, 3]); // no freezes
      expect(StreakEngine.effectiveCurrent(s, day(5)), 0);
    });

    test('keeps showing the streak while freezes could still save it', () {
      final s = after([1, 2, 3, 4, 5, 6, 7]); // 1 freeze
      expect(StreakEngine.effectiveCurrent(s, day(9)), 7);
      expect(StreakEngine.effectiveCurrent(s, day(10)), 0);
    });

    test('is 0 before any activity', () {
      expect(StreakEngine.effectiveCurrent(StreakState.initial, day(1)), 0);
    });
  });
}
