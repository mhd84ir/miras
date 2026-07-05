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
import 'package:miras/core/widgets/couplet_view.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';

/// First-run flow: welcome → daily goal → notification opt-in.
/// Completing it sets the onboarded flag; the router never returns here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  var _page = 0;
  var _goal = 20;

  static const _goalOptions = [10, 20, 30, 50];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      // Persist the goal as the user leaves the goal step.
      if (_page == 1) {
        await ref.read(gamificationRepositoryProvider).setDailyXpGoal(_goal);
      }
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish({required bool wantsReminder}) async {
    final strings = AppLocalizations.of(context);
    final repo = ref.read(gamificationRepositoryProvider);

    if (wantsReminder) {
      final granted = await ref
          .read(notificationServiceProvider)
          .enableDaily(
            title: strings.notificationTitle,
            body: strings.notificationBody,
          );
      await repo.setNotificationsEnabled(enabled: granted);
    }
    await repo.setOnboarded();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _WelcomeStep(strings: strings),
                  _GoalStep(
                    strings: strings,
                    goal: _goal,
                    options: _goalOptions,
                    onChanged: (goal) => setState(() => _goal = goal),
                  ),
                  _NotifStep(strings: strings),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(
                MirasSpacing.screenMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step dots.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: i == _page ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsetsDirectional.symmetric(
                            horizontal: MirasSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? colors.firoozeh
                                : colors.hairline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: MirasSpacing.md),
                  if (_page < 2)
                    MirasButton(
                      label: strings.lessonContinue,
                      expand: true,
                      onPressed: _next,
                    )
                  else ...[
                    MirasButton(
                      label: strings.onboardNotifYes,
                      expand: true,
                      onPressed: () => _finish(wantsReminder: true),
                    ),
                    const SizedBox(height: MirasSpacing.sm),
                    MirasButton(
                      label: strings.onboardNotifSkip,
                      variant: MirasButtonVariant.text,
                      expand: true,
                      onPressed: () => _finish(wantsReminder: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Padding(
      padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.appTitle,
            textAlign: TextAlign.center,
            style: MirasTextStyles.display.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.lg),
          const CoupletView(
            hemistich1: 'به نام خداوند جان و خرد',
            hemistich2: 'کزین برتر اندیشه برنگذرد',
          ),
          const SizedBox(height: MirasSpacing.lg),
          Text(
            strings.onboardWelcomeTitle,
            textAlign: TextAlign.center,
            style: MirasTextStyles.headline.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.sm),
          Text(
            strings.onboardWelcomeBody,
            textAlign: TextAlign.center,
            style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.strings,
    required this.goal,
    required this.options,
    required this.onChanged,
  });

  final AppLocalizations strings;
  final int goal;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Padding(
      padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.bolt, size: 64, color: colors.zarrin),
          const SizedBox(height: MirasSpacing.lg),
          Text(
            strings.onboardGoalTitle,
            textAlign: TextAlign.center,
            style: MirasTextStyles.headline.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.sm),
          Text(
            strings.onboardGoalBody,
            textAlign: TextAlign.center,
            style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: MirasSpacing.lg),
          SegmentedButton<int>(
            segments: [
              for (final option in options)
                ButtonSegment(
                  value: option,
                  label: Text(PersianText.number(option)),
                ),
            ],
            selected: {goal},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _NotifStep extends StatelessWidget {
  const _NotifStep({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Padding(
      padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.notifications_active,
            size: 64,
            color: colors.firoozeh,
          ),
          const SizedBox(height: MirasSpacing.lg),
          Text(
            strings.onboardNotifTitle,
            textAlign: TextAlign.center,
            style: MirasTextStyles.headline.copyWith(color: colors.ink),
          ),
          const SizedBox(height: MirasSpacing.sm),
          Text(
            strings.onboardNotifBody,
            textAlign: TextAlign.center,
            style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
