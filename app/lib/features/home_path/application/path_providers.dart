import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/home_path/domain/lesson_progress.dart';

enum LessonNodeStatus { locked, available, completed }

/// One node on the learning path: a lesson plus its progress state.
@immutable
class LessonNode {
  const LessonNode({
    required this.lesson,
    required this.status,
    this.stars = 0,
  });

  final Lesson lesson;
  final LessonNodeStatus status;
  final int stars;
}

final chaptersProvider = FutureProvider<List<Chapter>>(
  (ref) => ref.watch(contentRepositoryProvider).chapters(),
);

final progressProvider = StreamProvider<Map<String, LessonProgress>>(
  (ref) => ref.watch(progressRepositoryProvider).watchAll(),
);

/// Path nodes for a chapter: a lesson unlocks when it is first or when the
/// previous lesson has been completed.
// ignore: specify_nonobvious_property_types — riverpod provider types are verbose
final lessonNodesProvider = FutureProvider.family<List<LessonNode>, String>((
  ref,
  chapterId,
) async {
  final lessons = await ref
      .watch(contentRepositoryProvider)
      .lessonsOf(chapterId);
  final progress = ref.watch(progressProvider).value ?? const {};

  return [
    for (final (i, lesson) in lessons.indexed)
      LessonNode(
        lesson: lesson,
        stars: progress[lesson.id]?.stars ?? 0,
        status: progress.containsKey(lesson.id)
            ? LessonNodeStatus.completed
            : (i == 0 || progress.containsKey(lessons[i - 1].id))
            ? LessonNodeStatus.available
            : LessonNodeStatus.locked,
      ),
  ];
});
