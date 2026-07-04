import 'package:miras/core/content/models.dart';

/// Read-only access to the content pack. Implementations are backed by the
/// bundled SQLite pack today and a CDN-updated pack later (ADR-0002) —
/// callers never know the difference.
abstract interface class ContentRepository {
  Future<List<Chapter>> chapters();

  Future<List<Lesson>> lessonsOf(String chapterId);

  /// Exercises of a lesson, ordered by position.
  Future<List<Exercise>> exercisesOf(String lessonId);

  Future<Verse?> verse(String id);

  Future<VocabItem?> vocab(String id);

  Future<List<VocabItem>> vocabByIds(List<String> ids);

  /// Every vocabulary item in the pack — the review deck's distractor pool.
  Future<List<VocabItem>> allVocab();

  Future<RetellingSection?> retelling(String id);

  /// For the library reading view, in narrative order.
  Future<List<Verse>> versesOf(String chapterId);

  Future<List<RetellingSection>> retellingsOf(String chapterId);
}
