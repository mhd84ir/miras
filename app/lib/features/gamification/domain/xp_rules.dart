/// XP award rules (docs/DATA_MODEL.md §4). Single source of truth — UI and
/// services must never hardcode these numbers.
abstract final class XpRules {
  static const lessonCompleted = 10;
  static const perfectLessonBonus = 5;
  static const reviewSession = 5;
  static const perfectReviewBonus = 5;

  static const defaultDailyGoal = 20;

  /// XP for a completed lesson with [accuracy] in 0..1.
  static int forLesson({required double accuracy}) =>
      lessonCompleted + (accuracy >= 1 ? perfectLessonBonus : 0);

  /// XP for a completed review session.
  static int forReview({required bool allCorrect}) =>
      reviewSession + (allCorrect ? perfectReviewBonus : 0);
}

/// Where an XP award came from — persisted with each xp_event so future
/// leagues can consume the stream (ADR-0002).
enum XpSource { lesson, review, achievement }
