import 'package:flutter/foundation.dart';

/// FSRS memory state for one vocabulary item (docs/DATA_MODEL.md §2, §5).
@immutable
class SrsCard {
  const SrsCard({
    required this.vocabularyItemId,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.dueAt,
    this.lastReviewedAt,
    this.reps = 0,
    this.lapses = 0,
  });

  /// A card for a word seen for the first time: due immediately.
  factory SrsCard.fresh(String vocabularyItemId, DateTime now) => SrsCard(
    vocabularyItemId: vocabularyItemId,
    state: SrsState.newCard,
    stability: 0,
    difficulty: 0,
    dueAt: now,
  );

  final String vocabularyItemId;
  final SrsState state;

  /// FSRS memory stability in days (how long until retrievability drops
  /// to the request retention).
  final double stability;

  /// FSRS item difficulty, 1–10.
  final double difficulty;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final int reps;
  final int lapses;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  SrsCard copyWith({
    SrsState? state,
    double? stability,
    double? difficulty,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    int? reps,
    int? lapses,
  }) {
    return SrsCard(
      vocabularyItemId: vocabularyItemId,
      state: state ?? this.state,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
    );
  }
}

enum SrsState { newCard, learning, review, relearning }

/// Review grades, FSRS convention: 1=again … 4=easy.
enum SrsGrade {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const SrsGrade(this.value);

  final int value;
}
