import 'package:flutter/material.dart';

import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/miras_progress_bar.dart';

/// Chrome around every exercise: close button, progress bar, hearts on top;
/// scrollable exercise body; footer slot for feedback + action button
/// (DESIGN_SYSTEM.md §7).
class ExerciseScaffold extends StatelessWidget {
  const ExerciseScaffold({
    required this.progress,
    required this.hearts,
    required this.body,
    required this.footer,
    required this.onClose,
    super.key,
  });

  final double progress;
  final int hearts;
  final Widget body;
  final Widget footer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MirasSpacing.md,
                vertical: MirasSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: colors.inkMuted),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                  ),
                  Expanded(child: MirasProgressBar(value: progress)),
                  const SizedBox(width: MirasSpacing.md),
                  _HeartsChip(hearts: hearts),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(
                  MirasSpacing.screenMargin,
                ),
                child: body,
              ),
            ),
            footer,
          ],
        ),
      ),
    );
  }
}

class _HeartsChip extends StatelessWidget {
  const _HeartsChip({required this.hearts});

  final int hearts;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Semantics(
      label: PersianText.number(hearts),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: colors.anari, size: 22),
          const SizedBox(width: MirasSpacing.xs),
          Text(
            PersianText.number(hearts),
            style: MirasTextStyles.title.copyWith(color: colors.anari),
          ),
        ],
      ),
    );
  }
}

/// The footer in its two states: check (question phase) or feedback +
/// continue (feedback phase).
class ExerciseFooter extends StatelessWidget {
  const ExerciseFooter({
    required this.button,
    this.feedback,
    super.key,
  });

  final Widget button;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (feedback != null) ...[
              feedback!,
              const SizedBox(height: MirasSpacing.md),
            ],
            button,
          ],
        ),
      ),
    );
  }
}

/// Correct/incorrect feedback shown above the continue button.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.correct,
    required this.title,
    this.detail,
    super.key,
  });

  final bool correct;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final color = correct ? colors.sabz : colors.anari;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 28,
          ),
          const SizedBox(width: MirasSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MirasTextStyles.title.copyWith(color: color),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: MirasTextStyles.body.copyWith(color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
