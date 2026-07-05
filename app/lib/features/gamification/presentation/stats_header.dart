import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/gamification/application/stats_providers.dart';

/// Streak · daily XP · hearts, pinned above the learning path
/// (DESIGN_SYSTEM.md §7 StatChips).
class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mirasColors;
    final streak = ref.watch(effectiveStreakProvider);
    final todayXp = ref.watch(todayXpProvider).value ?? 0;
    final goal = ref.watch(profileProvider).value?.dailyXpGoal ?? 20;
    final hearts = ref.watch(heartsDisplayProvider).value?.count ?? 0;

    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MirasSpacing.screenMargin,
        vertical: MirasSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatChip(
            icon: Icons.local_fire_department,
            color: colors.atash,
            label: PersianText.number(streak),
            semanticLabel: strings.semStreak(PersianText.number(streak)),
          ),
          _StatChip(
            icon: Icons.bolt,
            color: colors.zarrin,
            label:
                '${PersianText.number(todayXp)} / ${PersianText.number(goal)}',
            semanticLabel: strings.semTodayXp(
              PersianText.number(todayXp),
              PersianText.number(goal),
            ),
          ),
          _StatChip(
            icon: Icons.favorite,
            color: colors.anari,
            label: PersianText.number(hearts),
            semanticLabel: strings.semHearts(PersianText.number(hearts)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: MirasSpacing.xs),
          Text(
            label,
            style: MirasTextStyles.title.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
