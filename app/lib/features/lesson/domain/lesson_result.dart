import 'package:flutter/foundation.dart';

/// Outcome of a completed lesson (docs/DATA_MODEL.md §4).
@immutable
class LessonResult {
  const LessonResult({
    required this.lessonId,
    required this.interactiveCount,
    required this.correctFirstTry,
  }) : assert(
         correctFirstTry <= interactiveCount,
         'correct answers cannot exceed interactive exercises',
       );

  final String lessonId;

  /// Number of non-presentation exercises in the lesson.
  final int interactiveCount;

  /// Exercises answered correctly on the first attempt.
  final int correctFirstTry;

  /// 1.0 for lessons with no interactive exercises (pure presentation).
  double get accuracy =>
      interactiveCount == 0 ? 1 : correctFirstTry / interactiveCount;

  /// ★ <80% · ★★ <100% · ★★★ 100%
  int get stars {
    if (accuracy >= 1) return 3;
    if (accuracy >= 0.8) return 2;
    return 1;
  }
}
