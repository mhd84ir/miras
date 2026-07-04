import 'package:flutter/material.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/couplet_view.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

/// vocabIntro: word, pronunciation, meaning, etymology.
class VocabIntroView extends StatelessWidget {
  const VocabIntroView({required this.loaded, super.key});

  final LoadedExercise loaded;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final vocab = loaded.vocab!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MirasSpacing.xl),
        Text(
          vocab.word,
          textAlign: TextAlign.center,
          style: MirasTextStyles.display.copyWith(color: colors.ink),
        ),
        const SizedBox(height: MirasSpacing.xs),
        Text(
          vocab.pronunciation,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        _LabeledCard(label: strings.meaningLabel, body: vocab.meaning),
        if (vocab.etymology != null) ...[
          const SizedBox(height: MirasSpacing.md),
          _LabeledCard(label: strings.etymologyLabel, body: vocab.etymology!),
        ],
      ],
    );
  }
}

/// verseIntro: couplet, meaning, interpretation.
class VerseIntroView extends StatelessWidget {
  const VerseIntroView({required this.loaded, super.key});

  final LoadedExercise loaded;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final verse = loaded.verse!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MirasSpacing.lg),
        CoupletView(
          hemistich1: verse.hemistich1,
          hemistich2: verse.hemistich2,
        ),
        const SizedBox(height: MirasSpacing.lg),
        _LabeledCard(label: strings.meaningLabel, body: verse.meaning),
        if (verse.interpretation != null) ...[
          const SizedBox(height: MirasSpacing.md),
          _LabeledCard(
            label: strings.interpretationLabel,
            body: verse.interpretation!,
          ),
        ],
      ],
    );
  }
}

/// storySection: one section of the simplified retelling.
class StorySectionView extends StatelessWidget {
  const StorySectionView({required this.loaded, super.key});

  final LoadedExercise loaded;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(MirasRadii.lg),
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.lg),
        child: Text(
          loaded.retelling!.body,
          style: MirasTextStyles.body.copyWith(color: colors.ink, height: 2),
        ),
      ),
    );
  }
}

class _LabeledCard extends StatelessWidget {
  const _LabeledCard({required this.label, required this.body});

  final String label;
  final String body;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: MirasTextStyles.caption.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: MirasSpacing.xs),
            Text(body, style: MirasTextStyles.body.copyWith(color: colors.ink)),
          ],
        ),
      ),
    );
  }
}
