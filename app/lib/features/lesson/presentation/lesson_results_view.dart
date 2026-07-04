import 'package:flutter/material.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/lesson/application/lesson_controller.dart';

/// End-of-lesson screen: stars + accuracy on success, retry on failure.
/// Celebration animation (Rive) replaces the static icons in M4.
class LessonResultsView extends StatelessWidget {
  const LessonResultsView({
    required this.state,
    required this.onExit,
    required this.onRetry,
    required this.onGoReview,
    super.key,
  });

  final LessonState state;
  final VoidCallback onExit;
  final VoidCallback onRetry;

  /// Out-of-hearts recovery path: review practice refills hearts.
  final VoidCallback onGoReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final result = state.result;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              if (state.failed) ...[
                Icon(Icons.heart_broken, size: 72, color: colors.anari),
                const SizedBox(height: MirasSpacing.lg),
                Text(
                  state.outOfHearts
                      ? strings.heartsEmptyTitle
                      : strings.lessonFailedTitle,
                  textAlign: TextAlign.center,
                  style: MirasTextStyles.headline.copyWith(color: colors.ink),
                ),
                if (state.outOfHearts) ...[
                  const SizedBox(height: MirasSpacing.sm),
                  Text(
                    strings.heartsEmptyBody,
                    textAlign: TextAlign.center,
                    style: MirasTextStyles.body.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        i < (result?.stars ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 56,
                        color: i < (result?.stars ?? 0)
                            ? colors.zarrin
                            : colors.hairline,
                      ),
                  ],
                ),
                const SizedBox(height: MirasSpacing.lg),
                Text(
                  strings.lessonCompletedTitle,
                  textAlign: TextAlign.center,
                  style: MirasTextStyles.headline.copyWith(color: colors.ink),
                ),
                const SizedBox(height: MirasSpacing.sm),
                Text(
                  strings.lessonAccuracy(
                    PersianText.number(
                      ((result?.accuracy ?? 0) * 100).round(),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
                ),
              ],
              const Spacer(),
              if (state.failed) ...[
                MirasButton(
                  label: state.outOfHearts
                      ? strings.goToReview
                      : strings.lessonRetry,
                  expand: true,
                  onPressed: state.outOfHearts ? onGoReview : onRetry,
                ),
                const SizedBox(height: MirasSpacing.sm),
                MirasButton(
                  label: strings.lessonContinue,
                  variant: MirasButtonVariant.text,
                  expand: true,
                  onPressed: onExit,
                ),
              ] else
                MirasButton(
                  label: strings.lessonContinue,
                  expand: true,
                  onPressed: onExit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
