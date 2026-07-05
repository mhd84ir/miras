import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/content/models.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/tazhib_rosette.dart';
import 'package:miras/features/gamification/presentation/stats_header.dart';
import 'package:miras/features/home_path/application/path_providers.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';

/// The learning path: chapters in order, each with its lesson nodes.
class HomePathScreen extends ConsumerWidget {
  const HomePathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StatsHeader(),
            Expanded(
              child: chapters.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (list) => ListView(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: MirasSpacing.md,
                  ),
                  children: [
                    for (final chapter in list)
                      _ChapterSection(chapter: chapter),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterSection extends ConsumerWidget {
  const _ChapterSection({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mirasColors;
    final nodes = ref.watch(lessonNodesProvider(chapter.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: MirasSpacing.screenMargin,
            vertical: MirasSpacing.sm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MirasRadii.lg),
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.lajvard),
              child: Stack(
                children: [
                  // Ornamental moment: a faint rosette bleeding off the corner.
                  PositionedDirectional(
                    end: -28,
                    top: -28,
                    child: TazhibRosette(
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.all(MirasSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: MirasTextStyles.headline.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: MirasSpacing.xs),
                        Text(
                          chapter.subtitle,
                          style: MirasTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        nodes.when(
          loading: () => const Padding(
            padding: EdgeInsetsDirectional.all(MirasSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (list) => Column(
            children: [
              for (final node in list)
                LessonPathNode(
                  node: node,
                  onTap: () => context.push('/lesson/${node.lesson.id}'),
                ),
            ],
          ),
        ),
        const SizedBox(height: MirasSpacing.lg),
      ],
    );
  }
}
