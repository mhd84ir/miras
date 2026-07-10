import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'user_database.g.dart';

/// Mutable on-device user store (docs/DATA_MODEL.md §2). All mutable tables
/// carry created/updated timestamps from day one to keep future sync
/// tractable (ADR-0002). Timestamps are UTC ISO-8601 strings; streak dates
/// are local calendar dates (yyyy-MM-dd).

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

class UserProfileRows extends Table {
  @override
  String get tableName => 'user_profile';

  /// Always the single row id 1.
  IntColumn get id => integer()();
  TextColumn get createdAt => text().named('created_at')();
  IntColumn get dailyXpGoal =>
      integer().named('daily_xp_goal').withDefault(const Constant(20))();
  BoolColumn get notificationsEnabled => boolean()
      .named('notifications_enabled')
      .withDefault(const Constant(false))();
  BoolColumn get soundEnabled =>
      boolean().named('sound_enabled').withDefault(const Constant(true))();
  BoolColumn get hapticsEnabled =>
      boolean().named('haptics_enabled').withDefault(const Constant(true))();

  /// 'system' | 'light' | 'dark' — parsed into ThemeMode by the UI layer.
  TextColumn get themeMode =>
      text().named('theme_mode').withDefault(const Constant('system'))();
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SrsCardRows extends Table {
  @override
  String get tableName => 'srs_cards';

  TextColumn get vocabularyItemId => text().named('vocabulary_item_id')();
  TextColumn get state => text()();
  RealColumn get stability => real()();
  RealColumn get difficulty => real()();
  TextColumn get dueAt => text().named('due_at')();
  TextColumn get lastReviewedAt =>
      text().named('last_reviewed_at').nullable()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {vocabularyItemId};
}

class XpEventRows extends Table {
  @override
  String get tableName => 'xp_events';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get source => text()();
  TextColumn get sourceId => text().named('source_id')();
  TextColumn get earnedAt => text().named('earned_at')();
}

class StreakRows extends Table {
  @override
  String get tableName => 'streak';

  /// Always the single row id 1.
  IntColumn get id => integer()();
  IntColumn get current => integer()();
  IntColumn get longest => integer()();

  /// Local calendar date, yyyy-MM-dd.
  TextColumn get lastActiveDate =>
      text().named('last_active_date').nullable()();
  IntColumn get freezesAvailable => integer().named('freezes_available')();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HeartsRows extends Table {
  @override
  String get tableName => 'hearts';

  /// Always the single row id 1.
  IntColumn get id => integer()();
  IntColumn get count => integer()();
  TextColumn get lastRefillAt => text().named('last_refill_at')();
  TextColumn get updatedAt => text().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AchievementRows extends Table {
  @override
  String get tableName => 'achievements';

  TextColumn get achievementId => text().named('achievement_id')();
  TextColumn get unlockedAt => text().named('unlocked_at')();

  @override
  Set<Column<Object>> get primaryKey => {achievementId};
}

@DriftDatabase(
  tables: [
    LessonProgressRows,
    ExerciseAttemptRows,
    UserProfileRows,
    SrsCardRows,
    XpEventRows,
    StreakRows,
    HeartsRows,
    AchievementRows,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  factory UserDatabase.open() {
    return UserDatabase(driftDatabase(name: 'miras_user'));
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: gamification + SRS (M3). Tables are created at the current
        // schema, so they already include every later column.
        await m.createTable(userProfileRows);
        await m.createTable(srsCardRows);
        await m.createTable(xpEventRows);
        await m.createTable(streakRows);
        await m.createTable(heartsRows);
        await m.createTable(achievementRows);
      }
      if (from == 2) {
        // v3: theme mode + onboarding flag (M4).
        await m.addColumn(userProfileRows, userProfileRows.themeMode);
        await m.addColumn(userProfileRows, userProfileRows.onboarded);
      }
      if (from >= 2 && from < 4) {
        // v4: haptics toggle (M8). Skipped for from<2 — createTable above
        // already produced the current schema.
        await m.addColumn(userProfileRows, userProfileRows.hapticsEnabled);
      }
    },
  );
}
