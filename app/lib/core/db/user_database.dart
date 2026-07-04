import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'user_database.g.dart';

/// Mutable on-device user store (docs/DATA_MODEL.md §2). All mutable tables
/// carry created/updated timestamps from day one to keep future sync
/// tractable (ADR-0002). Timestamps are UTC ISO-8601 strings.

class LessonProgressRows extends Table {
  @override
  String get tableName => 'lesson_progress';

  TextColumn get lessonId => text().named('lesson_id')();

  /// 0–3; 0 means attempted but never completed (not currently used).
  IntColumn get stars => integer()();
  RealColumn get bestAccuracy => real().named('best_accuracy')();
  TextColumn get completedAt => text().named('completed_at')();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {lessonId};
}

class ExerciseAttemptRows extends Table {
  @override
  String get tableName => 'exercise_attempts';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseId => text().named('exercise_id')();
  BoolColumn get wasCorrect => boolean().named('was_correct')();
  TextColumn get answeredAt => text().named('answered_at')();
  TextColumn get lessonSessionId => text().named('lesson_session_id')();
}

@DriftDatabase(tables: [LessonProgressRows, ExerciseAttemptRows])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  factory UserDatabase.open() {
    return UserDatabase(driftDatabase(name: 'miras_user'));
  }

  @override
  int get schemaVersion => 1;
}
