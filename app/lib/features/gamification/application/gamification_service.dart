import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/content_repository.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/achievements.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/gamification/domain/xp_rules.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';
import 'package:miras/features/review/data/srs_repository.dart';

/// Orchestrates the gamification rules around learning events. The pure
/// engines decide; the repositories remember; this service sequences.
class GamificationService {
  GamificationService(
    this._gamification,
    this._srs,
    this._progress,
    this._content, {
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final GamificationRepository _gamification;
  final SrsRepository _srs;
  final ProgressRepository _progress;
  final ContentRepository _content;
  final DateTime Function() _now;

  /// Lesson finished successfully: XP, streak day, SRS cards for newly
  /// introduced vocabulary, achievements.
  Future<void> onLessonCompleted(
    LessonResult result, {
    required List<String> introducedVocabIds,
  }) async {
    final now = _now();
    await _gamification.addXp(
      amount: XpRules.forLesson(accuracy: result.accuracy),
      source: XpSource.lesson,
      sourceId: result.lessonId,
      at: now,
    );
    await _registerStreakDay(now);
    await _srs.ensureCards(introducedVocabIds, now);
    await _evaluateAchievements(perfectLesson: result.accuracy >= 1);
  }

  /// Review session finished: XP, streak day, full heart refill.
  Future<void> onReviewCompleted({
    required bool allCorrect,
    required String sessionId,
  }) async {
    final now = _now();
    await _gamification.addXp(
      amount: XpRules.forReview(allCorrect: allCorrect),
      source: XpSource.review,
      sourceId: sessionId,
      at: now,
    );
    await _registerStreakDay(now);
    await _gamification.saveHearts(HeartsEconomy.refillFull(now));
    await _gamification.unlockAchievement(Achievements.firstReview.id, now);
    await _evaluateAchievements();
  }

  /// Hearts with lazy refill applied (and persisted when it changed).
  Future<HeartsState> settledHearts() async {
    final now = _now();
    final stored = await _gamification.hearts();
    final settled = HeartsEconomy.settle(stored, now);
    if (settled.count != stored.count) {
      await _gamification.saveHearts(settled);
    }
    return settled;
  }

  /// Spends one heart for a wrong lesson answer; returns the new state.
  Future<HeartsState> spendHeart() async {
    final now = _now();
    final settled = HeartsEconomy.settle(await _gamification.hearts(), now);
    final spent = HeartsEconomy.spend(settled, now);
    await _gamification.saveHearts(spent);
    return spent;
  }

  Future<void> _registerStreakDay(DateTime now) async {
    final streak = await _gamification.streak();
    final updated = StreakEngine.registerActivity(streak, now);
    await _gamification.saveStreak(updated);
  }

  Future<void> _evaluateAchievements({bool perfectLesson = false}) async {
    final now = _now();

    if (perfectLesson) {
      await _gamification.unlockAchievement(
        Achievements.perfectLesson.id,
        now,
      );
    }

    final streak = await _gamification.streak();
    if (streak.current >= 7) {
      await _gamification.unlockAchievement(Achievements.streak7.id, now);
    }
    if (streak.current >= 30) {
      await _gamification.unlockAchievement(Achievements.streak30.id, now);
    }

    if (await _srs.trackedCount() >= 20) {
      await _gamification.unlockAchievement(Achievements.vocab20.id, now);
    }

    final progress = await _progress.watchAll().first;
    if (progress.isNotEmpty) {
      await _gamification.unlockAchievement(
        Achievements.firstLesson.id,
        now,
      );
    }

    // Chapter complete: every lesson of any chapter finished.
    for (final chapter in await _content.chapters()) {
      final lessons = await _content.lessonsOf(chapter.id);
      if (lessons.isNotEmpty &&
          lessons.every((l) => progress.containsKey(l.id))) {
        await _gamification.unlockAchievement(
          Achievements.chapterComplete.id,
          now,
        );
        break;
      }
    }
  }
}

final gamificationServiceProvider = Provider<GamificationService>(
  (ref) => GamificationService(
    ref.watch(gamificationRepositoryProvider),
    ref.watch(srsRepositoryProvider),
    ref.watch(progressRepositoryProvider),
    ref.watch(contentRepositoryProvider),
  ),
);
