import 'package:flutter/material.dart' show ThemeMode;

import 'package:miras/core/content/content_repository.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/gamification/domain/xp_rules.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/home_path/domain/lesson_progress.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';
import 'package:miras/features/review/data/srs_repository.dart';
import 'package:miras/features/review/domain/srs_card.dart';

/// In-memory ContentRepository for widget/controller tests.
class FakeContentRepository implements ContentRepository {
  FakeContentRepository({
    this.chapterList = const [],
    this.lessonMap = const {},
    this.exerciseMap = const {},
    this.vocabMap = const {},
    this.verseMap = const {},
    this.retellingMap = const {},
  });

  final List<Chapter> chapterList;
  final Map<String, List<Lesson>> lessonMap;
  final Map<String, List<Exercise>> exerciseMap;
  final Map<String, VocabItem> vocabMap;
  final Map<String, Verse> verseMap;
  final Map<String, RetellingSection> retellingMap;

  @override
  Future<List<Chapter>> chapters() async => chapterList;

  @override
  Future<List<Lesson>> lessonsOf(String chapterId) async =>
      lessonMap[chapterId] ?? [];

  @override
  Future<List<Exercise>> exercisesOf(String lessonId) async =>
      exerciseMap[lessonId] ?? [];

  @override
  Future<VocabItem?> vocab(String id) async => vocabMap[id];

  @override
  Future<List<VocabItem>> vocabByIds(List<String> ids) async => [
    for (final id in ids) vocabMap[id]!,
  ];

  @override
  Future<List<VocabItem>> allVocab() async => vocabMap.values.toList();

  @override
  Future<Verse?> verse(String id) async => verseMap[id];

  @override
  Future<RetellingSection?> retelling(String id) async => retellingMap[id];

  @override
  Future<List<Verse>> versesOf(String chapterId) async => [
    for (final v in verseMap.values)
      if (v.chapterId == chapterId) v,
  ];

  @override
  Future<List<RetellingSection>> retellingsOf(String chapterId) async => [
    for (final r in retellingMap.values)
      if (r.chapterId == chapterId) r,
  ];
}

/// Records completions/attempts and lets tests seed prior progress.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({Map<String, LessonProgress>? initial})
    : _progress = {...?initial};

  final Map<String, LessonProgress> _progress;
  final completions = <LessonResult>[];
  final attempts = <(String, bool)>[];

  @override
  Stream<Map<String, LessonProgress>> watchAll() =>
      Stream.value(Map.unmodifiable(_progress));

  @override
  Future<void> recordCompletion(LessonResult result) async {
    completions.add(result);
    _progress[result.lessonId] = LessonProgress(
      lessonId: result.lessonId,
      stars: result.stars,
      bestAccuracy: result.accuracy,
      completedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<void> logAttempt({
    required String exerciseId,
    required bool wasCorrect,
    required String lessonSessionId,
  }) async {
    attempts.add((exerciseId, wasCorrect));
  }
}

/// In-memory gamification store with a controllable clock.
class FakeGamificationRepository implements GamificationRepository {
  FakeGamificationRepository({DateTime? now})
    : heartsState = HeartsEconomy.full(now ?? DateTime(2026));

  HeartsState heartsState;
  StreakState streakState = StreakState.initial;
  final xpEvents = <({int amount, XpSource source, DateTime at})>[];
  final unlocked = <String>{};
  int dailyXpGoal = XpRules.defaultDailyGoal;
  bool notificationsEnabled = false;
  ThemeMode themeMode = ThemeMode.system;
  bool onboarded = true;

  @override
  Future<HeartsState> hearts() async => heartsState;

  @override
  Stream<HeartsState> watchHearts() => Stream.value(heartsState);

  @override
  Future<void> saveHearts(HeartsState state) async => heartsState = state;

  @override
  Future<StreakState> streak() async => streakState;

  @override
  Stream<StreakState> watchStreak() => Stream.value(streakState);

  @override
  Future<void> saveStreak(StreakState state) async => streakState = state;

  @override
  Future<void> addXp({
    required int amount,
    required XpSource source,
    required String sourceId,
    required DateTime at,
  }) async {
    xpEvents.add((amount: amount, source: source, at: at));
  }

  @override
  Stream<int> watchXpOn(DateTime localNow) => Stream.value(
    [
      for (final e in xpEvents)
        if (e.at.year == localNow.year &&
            e.at.month == localNow.month &&
            e.at.day == localNow.day)
          e.amount,
    ].fold(0, (a, b) => a + b),
  );

  @override
  Future<int> totalXp() async => xpEvents.fold<int>(0, (a, e) => a + e.amount);

  @override
  Stream<Set<String>> watchUnlockedAchievements() => Stream.value(unlocked);

  @override
  Future<void> unlockAchievement(String id, DateTime at) async {
    unlocked.add(id);
  }

  @override
  Stream<UserProfileSettings> watchProfile() => Stream.value(
    (
      dailyXpGoal: dailyXpGoal,
      notificationsEnabled: notificationsEnabled,
      themeMode: themeMode,
      onboarded: onboarded,
    ),
  );

  @override
  Future<void> setThemeMode(ThemeMode mode) async => themeMode = mode;

  @override
  Future<void> setOnboarded() async => onboarded = true;

  @override
  Future<void> setDailyXpGoal(int xp) async => dailyXpGoal = xp;

  @override
  Future<void> setNotificationsEnabled({required bool enabled}) async =>
      notificationsEnabled = enabled;
}

/// In-memory SRS store.
class FakeSrsRepository implements SrsRepository {
  final cards = <String, SrsCard>{};

  @override
  Future<void> ensureCards(
    List<String> vocabularyItemIds,
    DateTime now,
  ) async {
    for (final id in vocabularyItemIds) {
      cards.putIfAbsent(id, () => SrsCard.fresh(id, now));
    }
  }

  @override
  Future<void> saveCard(SrsCard card) async =>
      cards[card.vocabularyItemId] = card;

  @override
  Future<List<SrsCard>> dueCards(DateTime now, {int limit = 20}) async {
    final due = cards.values.where((c) => c.isDue(now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return due.take(limit).toList();
  }

  @override
  Stream<int> watchDueCount(DateTime now) =>
      Stream.value(cards.values.where((c) => c.isDue(now)).length);

  @override
  Future<int> trackedCount() async => cards.length;
}

/// Content fixtures shared across tests — realistic Persian data.
abstract final class Fixtures {
  static const chapter = Chapter(
    id: 'zahak',
    position: 1,
    title: 'ضحاک و کاوهٔ آهنگر',
    subtitle: 'هزار سال بیداد',
    summary: 'داستان ضحاک ماردوش و قیام کاوه.',
  );

  static const lessons = [
    Lesson(
      id: 'zahak.l01',
      chapterId: 'zahak',
      position: 0,
      type: LessonType.vocab,
      title: 'واژگان ۱',
    ),
    Lesson(
      id: 'zahak.l02',
      chapterId: 'zahak',
      position: 1,
      type: LessonType.practice,
      title: 'تمرین ۱',
    ),
  ];

  static const vocab = VocabItem(
    id: 'vocab.dadkhah',
    word: 'دادخواه',
    pronunciation: 'dādkhāh',
    meaning: 'خواهانِ عدالت',
    etymology: 'از «داد» (عدالت) + «خواه» (خواهنده)',
    firstChapterId: 'zahak',
  );

  static const vocab2 = VocabItem(
    id: 'vocab.derafsh',
    word: 'درفش',
    pronunciation: 'derafsh',
    meaning: 'پرچم',
    firstChapterId: 'zahak',
  );

  static const verse = Verse(
    id: 'zahak.v010',
    chapterId: 'zahak',
    position: 0,
    hemistich1: 'چو ضحاک شد بر جهان شهریار',
    hemistich2: 'بر او سالیان انجمن شد هزار',
    meaning: 'چون ضحاک فرمانروای جهان شد، هزار سال پادشاهی کرد.',
    interpretation: 'بیت آغازین پادشاهی ضحاک.',
  );

  static const retelling = RetellingSection(
    id: 'zahak.r01',
    chapterId: 'zahak',
    position: 0,
    body: 'مرداس فرمانروایی نیک‌دل بود و پسرش ضحاک جوانی سبکسار.',
  );
}
