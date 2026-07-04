import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/gamification/application/stats_providers.dart';

/// Review tab root: due count + start, or the empty state. The session
/// itself runs on /review/session (ReviewSessionScreen).
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;
    final due = ref.watch(dueCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(strings.navReview)),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              due > 0 ? Icons.style : Icons.self_improvement,
              size: 72,
              color: due > 0 ? colors.firoozeh : colors.inkMuted,
            ),
            const SizedBox(height: MirasSpacing.lg),
            Text(
              due > 0
                  ? strings.reviewDueCount(PersianText.number(due))
                  : strings.reviewEmptyTitle,
              textAlign: TextAlign.center,
              style: MirasTextStyles.headline.copyWith(color: colors.ink),
            ),
            if (due == 0) ...[
              const SizedBox(height: MirasSpacing.sm),
              Text(
                strings.reviewEmptyBody,
                textAlign: TextAlign.center,
                style: MirasTextStyles.body.copyWith(color: colors.inkMuted),
              ),
            ],
            const Spacer(),
            if (due > 0)
              MirasButton(
                label: strings.reviewStart,
                expand: true,
                onPressed: () => context.push('/review/session'),
              ),
          ],
        ),
      ),
    );
  }
}
