import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/profile/domain/beta_metrics.dart';

/// Assembles the PRD §7 report from the user store on demand.
final FutureProvider<BetaMetricsReport> betaReportProvider =
    FutureProvider.autoDispose<BetaMetricsReport>((ref) async {
      final gamification = ref.watch(gamificationRepositoryProvider);
      final progress = ref.watch(progressRepositoryProvider);
      final now = DateTime.now();
      final streak = await gamification.streak();

      return BetaMetrics.compute(
        now: now,
        installedAt: await gamification.installedAt(),
        activatedAt: await progress.firstCompletionAt(),
        lessonsCompleted: (await progress.watchAll().first).length,
        effectiveStreak: StreakEngine.effectiveCurrent(streak, now),
        longestStreak: streak.longest,
        attempts: await progress.attemptHistory(),
      );
    });
