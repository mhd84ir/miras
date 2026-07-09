import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/notifications/notification_service.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/tazhib_rosette.dart';
import 'package:miras/features/gamification/application/recap_scheduler.dart';
import 'package:miras/features/gamification/application/stats_providers.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/achievements.dart';
import 'package:miras/features/review/data/srs_repository.dart';

/// Stats, achievements, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _goalOptions = [10, 20, 30, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;

    final totalXp = ref.watch(totalXpProvider).value ?? 0;
    final streak = ref.watch(streakProvider).value;
    final vocabCount = ref.watch(trackedVocabProvider).value ?? 0;
    final unlocked = ref.watch(unlockedAchievementsProvider).value ?? {};
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(strings.navProfile)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: strings.profileTotalXp,
                  value: PersianText.number(totalXp),
                  icon: Icons.bolt,
                  color: colors.zarrin,
                ),
              ),
              const SizedBox(width: MirasSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: strings.profileLongestStreak,
                  value: strings.statStreakDays(
                    PersianText.number(streak?.longest ?? 0),
                  ),
                  icon: Icons.local_fire_department,
                  color: colors.atash,
                ),
              ),
              const SizedBox(width: MirasSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: strings.profileVocabCount,
                  value: PersianText.number(vocabCount),
                  icon: Icons.translate,
                  color: colors.firoozeh,
                ),
              ),
            ],
          ),
          const SizedBox(height: MirasSpacing.xl),
          Text(
            strings.profileAchievements,
            style: MirasTextStyles.headline.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.md),
          for (final achievement in Achievements.all)
            _AchievementTile(
              achievement: achievement,
              unlocked: unlocked.contains(achievement.id),
            ),
          const SizedBox(height: MirasSpacing.xl),
          Text(
            strings.profileDailyGoal,
            style: MirasTextStyles.title.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.sm),
          SegmentedButton<int>(
            segments: [
              for (final goal in _goalOptions)
                ButtonSegment(
                  value: goal,
                  label: Text(PersianText.number(goal)),
                ),
            ],
            selected: {profile?.dailyXpGoal ?? 20},
            onSelectionChanged: (selection) => ref
                .read(gamificationRepositoryProvider)
                .setDailyXpGoal(selection.first),
          ),
          const SizedBox(height: MirasSpacing.lg),
          Text(
            strings.themeLabel,
            style: MirasTextStyles.title.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(strings.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(strings.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(strings.themeDark),
              ),
            ],
            selected: {profile?.themeMode ?? ThemeMode.system},
            onSelectionChanged: (selection) => ref
                .read(gamificationRepositoryProvider)
                .setThemeMode(selection.first),
          ),
          const SizedBox(height: MirasSpacing.md),
          SwitchListTile(
            title: Text(
              strings.profileSound,
              style: MirasTextStyles.body.copyWith(color: colors.ink),
            ),
            value: profile?.soundEnabled ?? true,
            onChanged: (enabled) => ref
                .read(gamificationRepositoryProvider)
                .setSoundEnabled(enabled: enabled),
          ),
          SwitchListTile(
            title: Text(
              strings.profileNotifications,
              style: MirasTextStyles.body.copyWith(color: colors.ink),
            ),
            value: profile?.notificationsEnabled ?? false,
            onChanged: (enabled) async {
              final repo = ref.read(gamificationRepositoryProvider);
              final notifications = ref.read(notificationServiceProvider);
              if (enabled) {
                final granted = await scheduleDailyRecap(
                  gamification: repo,
                  srs: ref.read(srsRepositoryProvider),
                  notifications: notifications,
                  strings: strings,
                );
                await repo.setNotificationsEnabled(enabled: granted);
              } else {
                await notifications.disableDaily();
                await repo.setNotificationsEnabled(enabled: false);
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            leading: Icon(Icons.query_stats, color: colors.inkMuted),
            title: Text(
              strings.profileBetaReport,
              style: MirasTextStyles.body.copyWith(color: colors.ink),
            ),
            onTap: () => context.push(AppRoutes.betaReport),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(MirasRadii.md),
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: MirasSpacing.xs),
            Text(
              value,
              style: MirasTextStyles.title.copyWith(color: colors.ink),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: MirasTextStyles.caption.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Tazhib ring crowns unlocked medals (DESIGN_SYSTEM.md §7).
                if (unlocked)
                  TazhibRosette(
                    size: 56,
                    color: colors.zarrin.withValues(alpha: 0.55),
                    strokeWidth: 1,
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? colors.zarrin.withValues(alpha: 0.15)
                        : colors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked ? colors.zarrin : colors.hairline,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    unlocked ? Icons.emoji_events : Icons.lock,
                    color: unlocked ? colors.zarrin : colors.inkMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MirasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: MirasTextStyles.title.copyWith(
                    color: unlocked ? colors.ink : colors.inkMuted,
                  ),
                ),
                Text(
                  achievement.description,
                  style: MirasTextStyles.bodySmall.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
