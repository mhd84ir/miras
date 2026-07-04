import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/review/data/srs_repository.dart';

/// Live stats for headers and the profile. autoDispose keeps the
/// "now"-anchored providers fresh on re-entry.

final StreamProvider<HeartsState> heartsDisplayProvider =
    StreamProvider.autoDispose<HeartsState>(
      (ref) => ref
          .watch(gamificationRepositoryProvider)
          .watchHearts()
          .map((s) => HeartsEconomy.settle(s, DateTime.now())),
    );

final StreamProvider<StreakState> streakProvider =
    StreamProvider.autoDispose<StreakState>(
      (ref) => ref.watch(gamificationRepositoryProvider).watchStreak(),
    );

/// The streak number users see (0 once unrecoverable).
final Provider<int> effectiveStreakProvider = Provider.autoDispose<int>((ref) {
  final streak = ref.watch(streakProvider).value;
  if (streak == null) return 0;
  return StreakEngine.effectiveCurrent(streak, DateTime.now());
});

final StreamProvider<int> todayXpProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(gamificationRepositoryProvider).watchXpOn(DateTime.now()),
);

final FutureProvider<int> totalXpProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(gamificationRepositoryProvider).totalXp(),
);

final StreamProvider<({int dailyXpGoal, bool notificationsEnabled})>
profileProvider =
    StreamProvider.autoDispose<({int dailyXpGoal, bool notificationsEnabled})>(
      (ref) => ref.watch(gamificationRepositoryProvider).watchProfile(),
    );

final StreamProvider<Set<String>> unlockedAchievementsProvider =
    StreamProvider.autoDispose<Set<String>>(
      (ref) =>
          ref.watch(gamificationRepositoryProvider).watchUnlockedAchievements(),
    );

final StreamProvider<int> dueCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(srsRepositoryProvider).watchDueCount(DateTime.now()),
);

final FutureProvider<int> trackedVocabProvider =
    FutureProvider.autoDispose<int>(
      (ref) => ref.watch(srsRepositoryProvider).trackedCount(),
    );
