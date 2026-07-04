import 'package:flutter_test/flutter_test.dart';

import 'package:miras/features/gamification/domain/hearts_economy.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('spend', () {
    test('spending from full starts the refill clock at now', () {
      final s = HeartsEconomy.spend(
        HeartsEconomy.full(t0.subtract(const Duration(days: 1))),
        t0,
      );
      expect(s.count, 4);
      expect(s.lastRefillAt, t0);
    });

    test('spending below full keeps the existing refill clock', () {
      var s = HeartsEconomy.spend(HeartsEconomy.full(t0), t0);
      s = HeartsEconomy.spend(s, t0.add(const Duration(minutes: 30)));
      expect(s.count, 3);
      expect(s.lastRefillAt, t0, reason: 'clock anchored to first spend');
    });

    test('spending at zero stays at zero', () {
      var s = HeartsEconomy.full(t0);
      for (var i = 0; i < 7; i++) {
        s = HeartsEconomy.spend(s, t0);
      }
      expect(s.count, 0);
    });
  });

  group('settle (lazy refill)', () {
    test('one heart returns after four hours', () {
      var s = HeartsEconomy.spend(HeartsEconomy.full(t0), t0);
      s = HeartsEconomy.settle(s, t0.add(const Duration(hours: 4)));
      expect(s.count, 5);
    });

    test('partial elapsed time earns nothing', () {
      var s = HeartsEconomy.spend(HeartsEconomy.full(t0), t0);
      s = HeartsEconomy.settle(
        s,
        t0.add(const Duration(hours: 3, minutes: 59)),
      );
      expect(s.count, 4);
    });

    test(
      'multiple intervals refill multiple hearts and keep the remainder',
      () {
        var s = HeartsEconomy.full(t0);
        for (var i = 0; i < 4; i++) {
          s = HeartsEconomy.spend(s, t0);
        }
        expect(s.count, 1);

        // 9 hours = 2 hearts earned, 1h leftover on the clock.
        s = HeartsEconomy.settle(s, t0.add(const Duration(hours: 9)));
        expect(s.count, 3);
        expect(s.lastRefillAt, t0.add(const Duration(hours: 8)));

        // The leftover hour counts toward the next heart.
        s = HeartsEconomy.settle(s, t0.add(const Duration(hours: 12)));
        expect(s.count, 4);
      },
    );

    test('never exceeds max', () {
      var s = HeartsEconomy.spend(HeartsEconomy.full(t0), t0);
      s = HeartsEconomy.settle(s, t0.add(const Duration(days: 10)));
      expect(s.count, HeartsEconomy.max);
    });

    test('full state is unaffected by time', () {
      final s = HeartsEconomy.settle(
        HeartsEconomy.full(t0),
        t0.add(const Duration(days: 3)),
      );
      expect(s.count, HeartsEconomy.max);
    });
  });

  group('nextRefillAt', () {
    test('null when full, lastRefill+4h otherwise', () {
      expect(HeartsEconomy.nextRefillAt(HeartsEconomy.full(t0)), isNull);
      final s = HeartsEconomy.spend(HeartsEconomy.full(t0), t0);
      expect(HeartsEconomy.nextRefillAt(s), t0.add(const Duration(hours: 4)));
    });
  });

  test('refillFull restores everything', () {
    final s = HeartsEconomy.refillFull(t0);
    expect(s.count, HeartsEconomy.max);
  });
}
