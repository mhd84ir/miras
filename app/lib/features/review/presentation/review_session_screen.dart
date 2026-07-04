import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/lesson/presentation/widgets/exercise_scaffold.dart';
import 'package:miras/features/lesson/presentation/widgets/option_tiles.dart';
import 'package:miras/features/review/application/review_controller.dart';

/// A running SRS review session. No hearts at stake — reading and reviewing
/// never punish (PRD product principle 2).
class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  int? _selected;
  int _selectedForIndex = -1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final controller = ref.read(reviewControllerProvider.notifier);
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;

    if (state.index != _selectedForIndex) {
      _selected = null;
      _selectedForIndex = state.index;
    }

    switch (state.phase) {
      case ReviewPhase.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case ReviewPhase.empty:
        // Session opened with nothing due (e.g. deep link) — bounce back.
        return Scaffold(
          body: Center(child: Text(strings.reviewEmptyTitle)),
        );

      case ReviewPhase.completed:
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(
                MirasSpacing.screenMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(Icons.favorite, size: 72, color: colors.anari),
                  const SizedBox(height: MirasSpacing.lg),
                  Text(
                    strings.reviewCompletedTitle,
                    textAlign: TextAlign.center,
                    style: MirasTextStyles.headline.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: MirasSpacing.sm),
                  Text(
                    strings.reviewHeartsRefilled,
                    textAlign: TextAlign.center,
                    style: MirasTextStyles.body.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  MirasButton(
                    label: strings.lessonContinue,
                    expand: true,
                    onPressed: () => context.go('/review'),
                  ),
                ],
              ),
            ),
          ),
        );

      case ReviewPhase.question || ReviewPhase.feedback:
        final current = state.current!;
        final isQuestion = state.phase == ReviewPhase.question;

        return ExerciseScaffold(
          progress: state.progress,
          onClose: () => context.go('/review'),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current.wordToMeaning
                    ? strings.reviewPromptMeaning
                    : strings.reviewPromptWord,
                style: MirasTextStyles.bodySmall.copyWith(
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: MirasSpacing.lg),
              Center(
                child: Text(
                  current.prompt,
                  textAlign: TextAlign.center,
                  style: current.wordToMeaning
                      ? MirasTextStyles.display.copyWith(color: colors.ink)
                      : MirasTextStyles.title.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(height: MirasSpacing.xl),
              OptionTiles(
                options: current.options,
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
                enabled: isQuestion,
              ),
            ],
          ),
          footer: ExerciseFooter(
            feedback: isQuestion
                ? null
                : FeedbackBanner(
                    correct: state.lastCorrect!,
                    title: state.lastCorrect!
                        ? strings.lessonCorrect
                        : strings.lessonWrongTitle,
                    detail: state.lastCorrect!
                        ? null
                        : current.options[current.correctIndex],
                  ),
            button: isQuestion
                ? MirasButton(
                    label: strings.lessonCheck,
                    expand: true,
                    onPressed: _selected == null
                        ? null
                        : () => controller.submit(_selected!),
                  )
                : MirasButton(
                    label: strings.lessonContinue,
                    expand: true,
                    onPressed: controller.next,
                  ),
          ),
        );
    }
  }
}
