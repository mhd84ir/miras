import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/gamification/domain/xp_rules.dart';

/// Persistence for XP, streak, hearts, achievements, and profile settings.
/// Domain rules live in the pure engines; this layer only stores state.
abstract interface class GamificationRepository {
  Stream<HeartsState> watchHearts();
  Future<HeartsState> hearts();
  Future<void> saveHearts(HeartsState state);

  Stream<StreakState> watchStreak();
  Future<StreakState> streak();
  Future<void> saveStreak(StreakState state);

  Future<void> addXp({
    required int amount,
    required XpSource source,
    required String sourceId,
    required DateTime at,
  });

  /// XP earned within the local calendar day containing [localNow].
  Stream<int> watchXpOn(DateTime localNow);
  Future<int> totalXp();

  Stream<Set<String>> watchUnlockedAchievements();
  Future<void> unlockAchievement(String id, DateTime at);

  /// Profile creation time — the "install moment" for beta metrics.
  Future<DateTime> installedAt();

  Stream<UserProfileSettings> watchProfile();
  Future<void> setDailyXpGoal(int xp);
  Future<void> setNotificationsEnabled({required bool enabled});
  Future<void> setSoundEnabled({required bool enabled});
  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setOnboarded();
}

/// Profile settings snapshot (docs/DATA_MODEL.md §2).
typedef UserProfileSettings = ({
  int dailyXpGoal,
  bool notificationsEnabled,
  bool soundEnabled,
  ThemeMode themeMode,
  bool onboarded,
});

class DriftGamificationRepository implements GamificationRepository {
  DriftGamificationRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final UserDatabase _db;
  final DateTime Function() _now;

  String get _ts => _now().toUtc().toIso8601String();

  /// Creates the singleton rows on first run so reads never special-case.
  Future<void> ensureSeeded() async {
    final now = _now();
    await _db
        .into(_db.userProfileRows)
        .insert(
          UserProfileRowsCompanion.insert(
            id: const Value(1),
            createdAt: _ts,
            updatedAt: _ts,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _db
        .into(_db.heartsRows)
        .insert(
          HeartsRowsCompanion.insert(
            id: const Value(1),
            count: HeartsEconomy.max,
            lastRefillAt: now.toUtc().toIso8601String(),
            updatedAt: _ts,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _db
        .into(_db.streakRows)
        .insert(
          StreakRowsCompanion.insert(
            id: const Value(1),
            current: 0,
            longest: 0,
            freezesAvailable: 0,
            updatedAt: _ts,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // ----------------------------------------------------------- hearts

  HeartsState _heartsFrom(HeartsRow r) => HeartsState(
    count: r.count,
    lastRefillAt: DateTime.parse(r.lastRefillAt),
  );

  @override
  Stream<HeartsState> watchHearts() =>
      _singleRow(_db.heartsRows).watchSingle().map(_heartsFrom);

  @override
  Future<HeartsState> hearts() async =>
      _heartsFrom(await _singleRow(_db.heartsRows).getSingle());

  @override
  Future<void> saveHearts(HeartsState state) async {
    await _db
        .update(_db.heartsRows)
        .write(
          HeartsRowsCompanion(
            count: Value(state.count),
            lastRefillAt: Value(state.lastRefillAt.toUtc().toIso8601String()),
            updatedAt: Value(_ts),
          ),
        );
  }

  // ----------------------------------------------------------- streak

  StreakState _streakFrom(StreakRow r) => StreakState(
    current: r.current,
    longest: r.longest,
    lastActiveDate: r.lastActiveDate == null
        ? null
        : DateTime.parse(r.lastActiveDate!),
    freezesAvailable: r.freezesAvailable,
  );

  @override
  Stream<StreakState> watchStreak() =>
      _singleRow(_db.streakRows).watchSingle().map(_streakFrom);

  @override
  Future<StreakState> streak() async =>
      _streakFrom(await _singleRow(_db.streakRows).getSingle());

  @override
  Future<void> saveStreak(StreakState state) async {
    final d = state.lastActiveDate;
    await _db
        .update(_db.streakRows)
        .write(
          StreakRowsCompanion(
            current: Value(state.current),
            longest: Value(state.longest),
            lastActiveDate: Value(
              d == null
                  ? null
                  : '${d.year.toString().padLeft(4, '0')}-'
                        '${d.month.toString().padLeft(2, '0')}-'
                        '${d.day.toString().padLeft(2, '0')}',
            ),
            freezesAvailable: Value(state.freezesAvailable),
            updatedAt: Value(_ts),
          ),
        );
  }

  // --------------------------------------------------------------- xp

  @override
  Future<void> addXp({
    required int amount,
    required XpSource source,
    required String sourceId,
    required DateTime at,
  }) async {
    await _db
        .into(_db.xpEventRows)
        .insert(
          XpEventRowsCompanion.insert(
            amount: amount,
            source: source.name,
            sourceId: sourceId,
            earnedAt: at.toUtc().toIso8601String(),
          ),
        );
  }

  @override
  Stream<int> watchXpOn(DateTime localNow) {
    final dayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final from = dayStart.toUtc().toIso8601String();
    final to = dayStart.add(const Duration(days: 1)).toUtc().toIso8601String();

    final sum = _db.xpEventRows.amount.sum();
    final query = _db.selectOnly(_db.xpEventRows)
      ..addColumns([sum])
      ..where(_db.xpEventRows.earnedAt.isBetweenValues(from, to));
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  @override
  Future<int> totalXp() async {
    final sum = _db.xpEventRows.amount.sum();
    final query = _db.selectOnly(_db.xpEventRows)..addColumns([sum]);
    return (await query.getSingle()).read(sum) ?? 0;
  }

  // ----------------------------------------------------- achievements

  @override
  Stream<Set<String>> watchUnlockedAchievements() => _db
      .select(_db.achievementRows)
      .watch()
      .map(
        (rows) => {for (final r in rows) r.achievementId},
      );

  @override
  Future<void> unlockAchievement(String id, DateTime at) async {
    await _db
        .into(_db.achievementRows)
        .insert(
          AchievementRowsCompanion.insert(
            achievementId: id,
            unlockedAt: at.toUtc().toIso8601String(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // ---------------------------------------------------------- profile

  @override
  Future<DateTime> installedAt() async => DateTime.parse(
    (await _singleRow(_db.userProfileRows).getSingle()).createdAt,
  );

  @override
  Stream<UserProfileSettings> watchProfile() =>
      _singleRow(_db.userProfileRows).watchSingle().map(
        (r) => (
          dailyXpGoal: r.dailyXpGoal,
          notificationsEnabled: r.notificationsEnabled,
          soundEnabled: r.soundEnabled,
          themeMode:
              ThemeMode.values.asNameMap()[r.themeMode] ?? ThemeMode.system,
          onboarded: r.onboarded,
        ),
      );

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _db
        .update(_db.userProfileRows)
        .write(
          UserProfileRowsCompanion(
            themeMode: Value(mode.name),
            updatedAt: Value(_ts),
          ),
        );
  }

  @override
  Future<void> setOnboarded() async {
    await _db
        .update(_db.userProfileRows)
        .write(
          UserProfileRowsCompanion(
            onboarded: const Value(true),
            updatedAt: Value(_ts),
          ),
        );
  }

  @override
  Future<void> setDailyXpGoal(int xp) async {
    await _db
        .update(_db.userProfileRows)
        .write(
          UserProfileRowsCompanion(
            dailyXpGoal: Value(xp),
            updatedAt: Value(_ts),
          ),
        );
  }

  @override
  Future<void> setNotificationsEnabled({required bool enabled}) async {
    await _db
        .update(_db.userProfileRows)
        .write(
          UserProfileRowsCompanion(
            notificationsEnabled: Value(enabled),
            updatedAt: Value(_ts),
          ),
        );
  }

  @override
  Future<void> setSoundEnabled({required bool enabled}) async {
    await _db
        .update(_db.userProfileRows)
        .write(
          UserProfileRowsCompanion(
            soundEnabled: Value(enabled),
            updatedAt: Value(_ts),
          ),
        );
  }

  SimpleSelectStatement<T, R> _singleRow<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
  ) => _db.select(table)..limit(1);
}

/// Overridden with the Drift-backed implementation at bootstrap.
final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => throw UnimplementedError(
    'gamificationRepositoryProvider must be overridden at app bootstrap',
  ),
);
