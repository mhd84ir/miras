import 'dart:math';

import 'package:miras/features/review/domain/srs_card.dart';

/// FSRS-4.5 scheduler (ADR-0006) with the published default parameters.
///
/// Reference: https://github.com/open-spaced-repetition/fsrs4anki — the
/// algorithm is implemented from the published formulas; behavior is locked
/// in by unit tests (monotonicity, interval growth, lapse handling).
/// Per-user parameter optimization is out of MVP scope.
class FsrsScheduler {
  const FsrsScheduler({
    this.requestRetention = 0.9,
    this.maximumIntervalDays = 365,
  });

  /// Target probability of recall at the scheduled review time.
  final double requestRetention;

  /// Cap on scheduling horizon; keeps a beta-phase mistake from pushing a
  /// card years away.
  final int maximumIntervalDays;

  /// FSRS-4.5 default parameters (w0..w16).
  static const List<double> _w = [
    0.4872, 1.4003, 3.7145, 13.8206, // w0-3: initial stability per grade
    5.1618, 1.2298, // w4-5: initial difficulty
    0.8975, 0.031, // w6-7: difficulty update + mean reversion
    1.6474, 0.1367, 1.0461, // w8-10: recall stability
    2.1072, 0.0793, 0.3246, 1.587, // w11-14: forget stability
    0.2272, 2.8755, // w15-16: hard penalty / easy bonus
  ];

  static const double _decay = -0.5;

  /// Chosen so R(t=S) = requestRetention when requestRetention is 0.9.
  static const double _factor = 19.0 / 81.0;

  /// Probability of recall [elapsedDays] after a review that left the card
  /// with [stability].
  double retrievability(double elapsedDays, double stability) {
    if (stability <= 0) return 0;
    return pow(1 + _factor * elapsedDays / stability, _decay).toDouble();
  }

  /// Days until retrievability decays to [requestRetention].
  int intervalFor(double stability) {
    final days = stability / _factor * (pow(requestRetention, 1 / _decay) - 1);
    return days.round().clamp(1, maximumIntervalDays);
  }

  /// Applies a review with [grade] at [now], returning the updated card.
  SrsCard review(SrsCard card, SrsGrade grade, DateTime now) {
    final isFirstReview =
        card.state == SrsState.newCard || card.lastReviewedAt == null;

    final double stability;
    final double difficulty;
    if (isFirstReview) {
      stability = _initStability(grade);
      difficulty = _initDifficulty(grade);
    } else {
      final elapsedDays =
          now.difference(card.lastReviewedAt!).inMinutes / (60 * 24);
      final r = retrievability(max(0, elapsedDays), card.stability);
      difficulty = _nextDifficulty(card.difficulty, grade);
      stability = grade == SrsGrade.again
          ? _forgetStability(card.difficulty, card.stability, r)
          : _recallStability(card.difficulty, card.stability, r, grade);
    }

    final lapsed = !isFirstReview && grade == SrsGrade.again;
    final nextState = switch (grade) {
      SrsGrade.again => isFirstReview ? SrsState.learning : SrsState.relearning,
      _ => SrsState.review,
    };

    // "Again" answers come back within the same session rather than in days.
    final due = grade == SrsGrade.again
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: intervalFor(stability)));

    return card.copyWith(
      state: nextState,
      stability: stability,
      difficulty: difficulty,
      dueAt: due,
      lastReviewedAt: now,
      reps: card.reps + 1,
      lapses: card.lapses + (lapsed ? 1 : 0),
    );
  }

  double _initStability(SrsGrade grade) => max(0.1, _w[grade.value - 1]);

  double _initDifficulty(SrsGrade grade) =>
      _clampDifficulty(_w[4] - (grade.value - 3) * _w[5]);

  double _nextDifficulty(double d, SrsGrade grade) {
    final updated = d - _w[6] * (grade.value - 3);
    // Mean reversion toward the initial difficulty of "easy".
    final reverted =
        _w[7] * _initDifficulty(SrsGrade.easy) + (1 - _w[7]) * updated;
    return _clampDifficulty(reverted);
  }

  double _recallStability(
    double d,
    double s,
    double r,
    SrsGrade grade,
  ) {
    final hardPenalty = grade == SrsGrade.hard ? _w[15] : 1.0;
    final easyBonus = grade == SrsGrade.easy ? _w[16] : 1.0;
    return s *
        (1 +
            exp(_w[8]) *
                (11 - d) *
                pow(s, -_w[9]) *
                (exp(_w[10] * (1 - r)) - 1) *
                hardPenalty *
                easyBonus);
  }

  double _forgetStability(double d, double s, double r) {
    return min(
      _w[11] *
          pow(d, -_w[12]) *
          (pow(s + 1, _w[13]) - 1) *
          exp(_w[14] * (1 - r)),
      s, // A lapse can never leave the card more stable than before.
    );
  }

  double _clampDifficulty(double d) => d.clamp(1, 10);
}
