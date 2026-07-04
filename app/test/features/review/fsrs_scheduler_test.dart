import 'package:flutter_test/flutter_test.dart';

import 'package:miras/features/review/domain/fsrs_scheduler.dart';
import 'package:miras/features/review/domain/srs_card.dart';

void main() {
  const scheduler = FsrsScheduler();
  final t0 = DateTime.utc(2026, 1, 1, 12);

  SrsCard fresh() => SrsCard.fresh('vocab.kherad', t0);

  group('first review', () {
    test('higher grades produce longer first intervals', () {
      final again = scheduler.review(fresh(), SrsGrade.again, t0);
      final hard = scheduler.review(fresh(), SrsGrade.hard, t0);
      final good = scheduler.review(fresh(), SrsGrade.good, t0);
      final easy = scheduler.review(fresh(), SrsGrade.easy, t0);

      expect(hard.stability, greaterThan(again.stability));
      expect(good.stability, greaterThan(hard.stability));
      expect(easy.stability, greaterThan(good.stability));
      expect(easy.dueAt.isAfter(good.dueAt), isTrue);
    });

    test('"again" on a new card stays in learning and comes back soon', () {
      final card = scheduler.review(fresh(), SrsGrade.again, t0);
      expect(card.state, SrsState.learning);
      expect(card.dueAt.difference(t0), const Duration(minutes: 10));
      expect(card.lapses, 0, reason: 'a new card cannot lapse');
    });

    test('harder grades yield higher difficulty', () {
      final hard = scheduler.review(fresh(), SrsGrade.hard, t0);
      final easy = scheduler.review(fresh(), SrsGrade.easy, t0);
      expect(hard.difficulty, greaterThan(easy.difficulty));
    });
  });

  group('subsequent reviews', () {
    test('repeated "good" grows the interval monotonically', () {
      var card = scheduler.review(fresh(), SrsGrade.good, t0);
      var previousStability = card.stability;
      var when = card.dueAt;

      for (var i = 0; i < 5; i++) {
        card = scheduler.review(card, SrsGrade.good, when);
        expect(
          card.stability,
          greaterThan(previousStability),
          reason: 'review #${i + 2} must increase stability',
        );
        previousStability = card.stability;
        when = card.dueAt;
      }
      expect(card.state, SrsState.review);
      expect(card.reps, 6);
    });

    test('a lapse reduces stability, increments lapses, and re-learns', () {
      var card = scheduler.review(fresh(), SrsGrade.good, t0);
      card = scheduler.review(card, SrsGrade.good, card.dueAt);
      final stableBefore = card.stability;

      final lapsed = scheduler.review(card, SrsGrade.again, card.dueAt);
      expect(lapsed.stability, lessThan(stableBefore));
      expect(lapsed.lapses, 1);
      expect(lapsed.state, SrsState.relearning);
    });

    test('easy produces a longer next interval than hard', () {
      final base = scheduler.review(fresh(), SrsGrade.good, t0);
      final whenDue = base.dueAt;

      final afterHard = scheduler.review(base, SrsGrade.hard, whenDue);
      final afterEasy = scheduler.review(base, SrsGrade.easy, whenDue);
      expect(afterEasy.dueAt.isAfter(afterHard.dueAt), isTrue);
    });

    test('difficulty stays within 1..10 under extreme sequences', () {
      var card = scheduler.review(fresh(), SrsGrade.again, t0);
      for (var i = 0; i < 30; i++) {
        card = scheduler.review(card, SrsGrade.again, card.dueAt);
        expect(card.difficulty, inInclusiveRange(1, 10));
      }
      for (var i = 0; i < 30; i++) {
        card = scheduler.review(card, SrsGrade.easy, card.dueAt);
        expect(card.difficulty, inInclusiveRange(1, 10));
      }
    });

    test('intervals never exceed the configured maximum', () {
      var card = scheduler.review(fresh(), SrsGrade.easy, t0);
      for (var i = 0; i < 20; i++) {
        card = scheduler.review(card, SrsGrade.easy, card.dueAt);
      }
      expect(
        card.dueAt.difference(card.lastReviewedAt!).inDays,
        lessThanOrEqualTo(365),
      );
    });
  });

  group('retrievability', () {
    test('equals request retention exactly one stability-interval later', () {
      expect(
        scheduler.retrievability(10, 10),
        closeTo(0.9, 0.001),
        reason: 'R(t=S) must equal 0.9 by construction of the factor',
      );
    });

    test('decays over time', () {
      final early = scheduler.retrievability(1, 10);
      final late = scheduler.retrievability(30, 10);
      expect(early, greaterThan(late));
    });
  });
}
