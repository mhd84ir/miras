import 'package:flutter/material.dart';

import 'package:miras/core/content/models.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/home_path/application/path_providers.dart';

/// One stop on the learning path (DESIGN_SYSTEM.md §7).
class LessonPathNode extends StatelessWidget {
  const LessonPathNode({
    required this.node,
    required this.onTap,
    super.key,
  });

  final LessonNode node;
  final VoidCallback? onTap;

  static const Map<LessonType, IconData> _icons = {
    LessonType.vocab: Icons.translate,
    LessonType.practice: Icons.fitness_center,
    LessonType.verses: Icons.auto_stories,
    LessonType.story: Icons.menu_book,
    LessonType.review: Icons.replay,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final locked = node.status == LessonNodeStatus.locked;
    final completed = node.status == LessonNodeStatus.completed;

    final circleColor = switch (node.status) {
      LessonNodeStatus.locked => colors.surfaceVariant,
      LessonNodeStatus.available => colors.firoozeh,
      LessonNodeStatus.completed => colors.zarrin,
    };

    return Semantics(
      button: !locked,
      enabled: !locked,
      label: node.lesson.title,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(MirasRadii.lg),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: MirasSpacing.sm,
            horizontal: MirasSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: completed
                      ? Border.all(color: colors.zarrin, width: 3)
                      : null,
                  boxShadow: locked
                      ? null
                      : [
                          BoxShadow(
                            color: circleColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Icon(
                  locked ? Icons.lock : _icons[node.lesson.type],
                  color: locked ? colors.inkMuted : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: MirasSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.lesson.title,
                      style: MirasTextStyles.title.copyWith(
                        color: locked ? colors.inkMuted : colors.ink,
                      ),
                    ),
                    if (completed)
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Icon(
                              i < node.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: i < node.stars
                                  ? colors.zarrin
                                  : colors.hairline,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
