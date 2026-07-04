import 'package:flutter/material.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';
import 'package:miras/features/lesson/presentation/widgets/option_tiles.dart';

/// multipleChoice and comprehension: question + options.
class QuestionChoiceView extends StatelessWidget {
  const QuestionChoiceView({
    required this.loaded,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (question, options) = switch (loaded.prompt) {
      MultipleChoicePrompt(:final question, :final options) => (
        question,
        options,
      ),
      ComprehensionPrompt(:final question, :final options) => (
        question,
        options,
      ),
      _ => throw StateError('not a question-choice prompt'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: MirasTextStyles.title.copyWith(
            color: context.mirasColors.ink,
          ),
        ),
        const SizedBox(height: MirasSpacing.lg),
        OptionTiles(
          options: options,
          selected: selected,
          onSelect: onSelect,
          enabled: enabled,
        ),
      ],
    );
  }
}

/// cloze: the couplet with one token blanked; options fill the blank.
class ClozeView extends StatelessWidget {
  const ClozeView({
    required this.loaded,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final prompt = loaded.prompt as ClozePrompt;
    final verse = loaded.verse!;

    final blankedTokens = [...verse.tokensOf(prompt.hemistich)];
    blankedTokens[prompt.blankToken] = selected == null
        ? '____'
        : prompt.options[selected!];
    final blankedLine = blankedTokens.join(' ');

    final otherLine = prompt.hemistich == 1
        ? verse.hemistich2
        : verse.hemistich1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.clozeInstruction,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        Column(
          children: [
            Text(
              prompt.hemistich == 1 ? blankedLine : otherLine,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: MirasTextStyles.verse.copyWith(
                color: prompt.hemistich == 1 && selected != null
                    ? colors.firoozeh
                    : colors.ink,
              ),
            ),
            const SizedBox(height: MirasSpacing.xs),
            Text(
              prompt.hemistich == 2 ? blankedLine : otherLine,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: MirasTextStyles.verse.copyWith(
                color: prompt.hemistich == 2 && selected != null
                    ? colors.firoozeh
                    : colors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: MirasSpacing.xl),
        OptionTiles(
          options: prompt.options,
          selected: selected,
          onSelect: onSelect,
          enabled: enabled,
        ),
      ],
    );
  }
}

/// listening: play button + options. Playback lands with the audio pipeline;
/// until packs carry audio these exercises are filtered out by LessonLoader.
class ListeningView extends StatelessWidget {
  const ListeningView({
    required this.loaded,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final prompt = loaded.prompt as ListeningPrompt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.listeningInstruction,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.firoozeh,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 40,
              padding: const EdgeInsetsDirectional.all(MirasSpacing.lg),
              // TODO(m4-audio): wire playback once packs carry audio assets.
              onPressed: () {},
              icon: const Icon(Icons.volume_up, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: MirasSpacing.xl),
        OptionTiles(
          options: prompt.options,
          selected: selected,
          onSelect: onSelect,
          enabled: enabled,
        ),
      ],
    );
  }
}
