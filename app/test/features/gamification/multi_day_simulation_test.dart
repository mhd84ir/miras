import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/db/user_database.dart';
import 'package:miras/features/gamification/application/gamification_service.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';
import 'package:miras/features/review/data/srs_repository.dart';
import 'package:miras/features/review/domain/fsrs_scheduler.dart';
import 'package:miras/features/review/domain/srs_card.dart';

import '../../helpers/fakes.dart';

/// M3 exit criterion (docs/ROADMAP.md): a multi-day simulated usage script
/// must produce correct streak/XP/SRS states — run against the REAL Drift
/// repositories on an in-memory database, with a scripted clock.
void main() {
  late UserDatabase db;
  late DriftGamificationRepository gamification;
  late DriftSrsRepository srs;
  late GamificationService service;

  /// The simulation's "now", advanced by the script.
  var clock = DateTime(2026, 3, 1, 18); // Sunday evening

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
    gamification = DriftGamificationRepository(db, clock: () => clock);
    srs = DriftSrsRepository(db, clock: () => clock);
    service = GamificationService(
      gamification,
      srs,
      FakeProgressRepository(),
      FakeContentRepository(),
      clock: () => clock,
    );
    await gamification.ensureSeeded();
  });

  tearDown(() => db.close());

  LessonResult lesson(String id, {double accuracy = 1}) => LessonResult(
    lessonId: id,
    interactiveCount: 10,
    correctFirstTry: (10 * accuracy).round(),
  );

  test(
    'a week of simulated usage produces correct streak, XP, and SRS state',
    () async {
      // --- Day 1: perfect lesson introducing two words.
      await service.onLessonCompleted(
        lesson('zahak.l01'),
        introducedVocabIds: ['vocab.kherad', 'vocab.derafsh'],
      );
      expect((await gamification.streak()).current, 1);
      expect(await gamification.totalXp(), 15);
      expect(await srs.dueCards(clock), hasLength(2), reason: 'fresh = due');

      // --- Day 1, later: review both words correctly.
      const scheduler = FsrsScheduler();
      for (final card in await srs.dueCards(clock)) {
        await srs.saveCard(scheduler.review(card, SrsGrade.good, clock));
      }
      await service.onReviewCompleted(allCorrect: true, sessionId: 'r1');
      expect(await gamification.totalXp(), 25, reason: '15 + 10 review');
      expect(
        (await gamification.streak()).current,
        1,
        reason: 'same day counts once',
      );
      expect(
        await srs.dueCards(clock),
        isEmpty,
        reason: 'good grades push cards into the future',
      );

      // --- Day 2: imperfect lesson; a wrong answer costs a heart.
      clock = clock.add(const Duration(days: 1));
      await service.spendHeart();
      await service.onLessonCompleted(
        lesson('zahak.l02', accuracy: 0.8),
        introducedVocabIds: [],
      );
      expect((await gamification.streak()).current, 2);
      expect(await gamification.totalXp(), 35, reason: 'no perfect bonus');
      expect((await service.settledHearts()).count, HeartsEconomy.max - 1);

      // --- Day 2 +4h: one heart lazily refills.
      clock = clock.add(const Duration(hours: 4));
      expect((await service.settledHearts()).count, HeartsEconomy.max);

      // --- Days 3–4: no activity. Day 5: streak resets (no freezes yet).
      clock = clock.add(const Duration(days: 3));
      await service.onLessonCompleted(
        lesson('zahak.l03'),
        introducedVocabIds: [],
      );
      final streak = await gamification.streak();
      expect(streak.current, 1, reason: 'two missed days, no freezes');
      expect(streak.longest, 2, reason: 'longest survives');

      // --- FSRS: the day-1 cards eventually come due again.
      final card = (await srs.dueCards(
        clock.add(const Duration(days: 60)),
      )).firstWhere((c) => c.vocabularyItemId == 'vocab.kherad');
      expect(card.reps, 1);
      expect(card.dueAt.isAfter(DateTime(2026, 3)), isTrue);

      // --- Persistence sanity: everything above lives in real tables.
      expect(await srs.trackedCount(), 2);
      final unlocked = await gamification.watchUnlockedAchievements().first;
      expect(unlocked, contains('perfect_lesson'));
      expect(unlocked, contains('first_review'));
    },
  );

  test('streak freeze earned at day 7 bridges a single missed day', () async {
    for (var day = 0; day < 7; day++) {
      await service.onLessonCompleted(
        lesson('zahak.l0$day'),
        introducedVocabIds: [],
      );
      clock = clock.add(const Duration(days: 1));
    }
    expect((await gamification.streak()).current, 7);
    expect((await gamification.streak()).freezesAvailable, 1);

    // Skip one day entirely, then resume: freeze silently consumed.
    clock = clock.add(const Duration(days: 1));
    await service.onLessonCompleted(
      lesson('zahak.l08'),
      introducedVocabIds: [],
    );
    final streak = await gamification.streak();
    expect(streak.current, 8);
    expect(streak.freezesAvailable, 0);
  });
}
