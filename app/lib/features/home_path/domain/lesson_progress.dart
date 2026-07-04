import 'package:flutter/foundation.dart';

/// A lesson's persisted completion state.
@immutable
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.stars,
    required this.bestAccuracy,
    required this.completedAt,
  });

  final String lessonId;
  final int stars;
  final double bestAccuracy;
  final DateTime completedAt;
}
