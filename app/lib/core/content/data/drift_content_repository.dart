import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:miras/core/content/content_repository.dart';
import 'package:miras/core/content/data/content_database.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';

class DriftContentRepository implements ContentRepository {
  DriftContentRepository(this._db);

  final ContentDatabase _db;

  @override
  Future<List<Chapter>> chapters() async {
    final rows = await (_db.select(
      _db.chapterRows,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return [
      for (final r in rows)
        Chapter(
          id: r.id,
          position: r.position,
          title: r.title,
          subtitle: r.subtitle,
          summary: r.summary,
          coverAsset: r.coverAsset,
        ),
    ];
  }

  @override
  Future<List<Lesson>> lessonsOf(String chapterId) async {
    final rows =
        await (_db.select(_db.lessonRows)
              ..where((t) => t.chapterId.equals(chapterId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        Lesson(
          id: r.id,
          chapterId: r.chapterId,
          position: r.position,
          type: LessonType.values.byName(r.type),
          title: r.title,
        ),
    ];
  }

  @override
  Future<List<Exercise>> exercisesOf(String lessonId) async {
    final rows =
        await (_db.select(_db.exerciseRows)
              ..where((t) => t.lessonId.equals(lessonId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        Exercise(
          id: r.id,
          lessonId: r.lessonId,
          position: r.position,
          prompt: ExercisePrompt.fromJson(
            r.type,
            jsonDecode(r.promptJson) as Map<String, Object?>,
          ),
          difficulty: r.difficulty,
        ),
    ];
  }

  @override
  Future<Verse?> verse(String id) async {
    final r = await (_db.select(
      _db.verseRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _verse(r);
  }

  @override
  Future<VocabItem?> vocab(String id) async {
    final r = await (_db.select(
      _db.vocabularyItemRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _vocab(r);
  }

  @override
  Future<List<VocabItem>> vocabByIds(List<String> ids) async {
    final rows = await (_db.select(
      _db.vocabularyItemRows,
    )..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: _vocab(r)};
    // Preserve the caller's order (matching boards rely on it).
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Future<List<VocabItem>> allVocab() async {
    final rows = await _db.select(_db.vocabularyItemRows).get();
    return rows.map(_vocab).toList();
  }

  @override
  Future<RetellingSection?> retelling(String id) async {
    final r = await (_db.select(
      _db.retellingRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _retelling(r);
  }

  @override
  Future<List<Verse>> versesOf(String chapterId) async {
    final rows =
        await (_db.select(_db.verseRows)
              ..where((t) => t.chapterId.equals(chapterId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return rows.map(_verse).toList();
  }

  @override
  Future<List<RetellingSection>> retellingsOf(String chapterId) async {
    final rows =
        await (_db.select(_db.retellingRows)
              ..where((t) => t.chapterId.equals(chapterId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return rows.map(_retelling).toList();
  }

  @override
  Future<List<Credit>> credits() async {
    final rows = await _db.select(_db.creditRows).get();
    return [
      for (final r in rows)
        Credit(id: r.id, kind: r.kind, name: r.name, url: r.url),
    ];
  }

  Verse _verse(VerseRow r) => Verse(
    id: r.id,
    chapterId: r.chapterId,
    position: r.position,
    hemistich1: r.hemistich1,
    hemistich2: r.hemistich2,
    meaning: r.meaning,
    interpretation: r.interpretation,
    audioAsset: r.audioAsset,
    source: r.source,
  );

  VocabItem _vocab(VocabularyItemRow r) => VocabItem(
    id: r.id,
    word: r.word,
    pronunciation: r.pronunciation,
    meaning: r.meaning,
    etymology: r.etymology,
    audioAsset: r.audioAsset,
    exampleVerseId: r.exampleVerseId,
    firstChapterId: r.firstChapterId,
  );

  RetellingSection _retelling(RetellingRow r) => RetellingSection(
    id: r.id,
    chapterId: r.chapterId,
    position: r.position,
    body: r.body,
    illustrationAsset: r.illustrationAsset,
  );
}
