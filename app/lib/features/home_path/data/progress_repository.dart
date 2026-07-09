import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/home_path/domain/lesson_progress.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';

/// Persistence for lesson completion and exercise attempts.
abstract interface class ProgressRepository {
  /// Live map of lessonId → progress; emits on every change.
  Stream<Map<String, LessonProgress>> watchAll();

  /// Records a completed lesson, keeping the best stars/accuracy achieved.
  Future<void> recordCompletion(LessonResult result);

  /// Append-only attempt log (difficulty tuning, future analytics).
  Future<void> logAttempt({
    required String exerciseId,
    required bool wasCorrect,
    required String lessonSessionId,
  });

  /// Every logged attempt as (when, correct), oldest first — feeds the
  /// PRD §7 accuracy trend.
  Future<List<({DateTime at, bool correct})>> attemptHistory();

  /// First-ever lesson completion (PRD §7 activation), null before it.
  Future<DateTime?> firstCompletionAt();
}

class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final UserDatabase _db;
  final DateTime Function() _now;

  String get _timestamp => _now().toUtc().toIso8601String();

  @override
  Stream<Map<String, LessonProgress>> watchAll() {
    return _db
        .select(_db.lessonProgressRows)
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              r.lessonId: LessonProgress(
                lessonId: r.lessonId,
                stars: r.stars,
                bestAccuracy: r.bestAccuracy,
                completedAt: DateTime.parse(r.completedAt),
              ),
          },
        );
  }

  @override
  Future<void> recordCompletion(LessonResult result) async {
    final existing = await (_db.select(
      _db.lessonProgressRows,
    )..where((t) => t.lessonId.equals(result.lessonId))).getSingleOrNull();

    final ts = _timestamp;
    await _db
        .into(_db.lessonProgressRows)
        .insertOnConflictUpdate(
          LessonProgressRowsCompanion.insert(
            lessonId: result.lessonId,
            stars: existing == null
                ? result.stars
                : (result.stars > existing.stars
                      ? result.stars
                      : existing.stars),
            bestAccuracy: existing == null
                ? result.accuracy
                : (result.accuracy > existing.bestAccuracy
                      ? result.accuracy
                      : existing.bestAccuracy),
            completedAt: ts,
            createdAt: existing?.createdAt ?? ts,
            updatedAt: ts,
          ),
        );
  }

  @override
  Future<void> logAttempt({
    required String exerciseId,
    required bool wasCorrect,
    required String lessonSessionId,
  }) async {
    await _db
        .into(_db.exerciseAttemptRows)
        .insert(
          ExerciseAttemptRowsCompanion.insert(
            exerciseId: exerciseId,
            wasCorrect: wasCorrect,
            answeredAt: _timestamp,
            lessonSessionId: lessonSessionId,
          ),
        );
  }

  @override
  Future<List<({DateTime at, bool correct})>> attemptHistory() async {
    final rows = await (_db.select(
      _db.exerciseAttemptRows,
    )..orderBy([(t) => OrderingTerm.asc(t.answeredAt)])).get();
    return [
      for (final r in rows)
        (at: DateTime.parse(r.answeredAt), correct: r.wasCorrect),
    ];
  }

  @override
  Future<DateTime?> firstCompletionAt() async {
    // ISO-8601 UTC strings order lexicographically, so min() is earliest.
    final earliest = _db.lessonProgressRows.createdAt.min();
    final query = _db.selectOnly(_db.lessonProgressRows)
      ..addColumns([earliest]);
    final value = (await query.getSingle()).read(earliest);
    return value == null ? null : DateTime.parse(value);
  }
}

/// Overridden with the Drift-backed implementation at bootstrap.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => throw UnimplementedError(
    'progressRepositoryProvider must be overridden at app bootstrap',
  ),
);
