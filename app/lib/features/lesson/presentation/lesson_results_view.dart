import 'dart:async';

import 'package:flutter/material.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/core/widgets/tazhib_rosette.dart';
import 'package:miras/features/lesson/application/lesson_controller.dart';

/// End-of-lesson screen. Success celebrates with a staggered star pop over
/// an illuminated rosette; the sequence is skipped entirely when the system
/// requests reduced motion (DESIGN_SYSTEM.md §5).
class LessonResultsView extends StatefulWidget {
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
  State<LessonResultsView> createState() => _LessonResultsViewState();
}

class _LessonResultsViewState extends State<LessonResultsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations || widget.state.failed) {
        _controller.value = 1;
      } else {
        unawaited(_controller.forward());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _star(int index) => CurvedAnimation(
    parent: _controller,
    curve: Interval(
      0.15 + index * 0.18,
      0.55 + index * 0.18,
      curve: Curves.elasticOut,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final state = widget.state;
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
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Illuminated backdrop blooming behind the stars.
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0, 0.4),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.7, end: 1).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0,
                                0.5,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                          child: TazhibRosette(
                            size: 220,
                            color: colors.zarrin.withValues(alpha: 0.35),
                            petals: 12,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            ScaleTransition(
                              scale: i < (result?.stars ?? 0)
                                  ? _star(i)
                                  : const AlwaysStoppedAnimation(1),
                              child: Icon(
                                i < (result?.stars ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 56,
                                color: i < (result?.stars ?? 0)
                                    ? colors.zarrin
                                    : colors.hairline,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MirasSpacing.sm),
                Text(
                  strings.lessonCompletedTitle,
                  textAlign: TextAlign.center,
                  style: MirasTextStyles.headline.copyWith(color: colors.ink),
                ),
                const SizedBox(height: MirasSpacing.sm),
                Text(
                  strings.lessonAccuracy(
                    PersianText.number(((result?.accuracy ?? 0) * 100).round()),
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
                  onPressed: state.outOfHearts
                      ? widget.onGoReview
                      : widget.onRetry,
                ),
                const SizedBox(height: MirasSpacing.sm),
                MirasButton(
                  label: strings.lessonContinue,
                  variant: MirasButtonVariant.text,
                  expand: true,
                  onPressed: widget.onExit,
                ),
              ] else
                MirasButton(
                  label: strings.lessonContinue,
                  expand: true,
                  onPressed: widget.onExit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
