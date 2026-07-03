import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/router/app_router.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/widgets/couplet_view.dart';
import 'package:miras/core/widgets/miras_button.dart';

/// Placeholder home screen (M0 shell). Replaced by the learning path in M2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                strings.appTitle,
                style: textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MirasSpacing.sm),
              Text(
                strings.homeTagline,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MirasSpacing.xl),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(MirasRadii.lg),
                  border: Border.all(color: colors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(MirasSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        strings.homeOpeningVerseCaption,
                        style: textTheme.labelSmall,
                      ),
                      const SizedBox(height: MirasSpacing.md),
                      const CoupletView(
                        hemistich1: 'به نام خداوند جان و خرد',
                        hemistich2: 'کزین برتر اندیشه برنگذرد',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              MirasButton(
                label: strings.homeStartButton,
                expand: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.homeComingSoon)),
                  );
                },
              ),
              if (kDebugMode) ...[
                const SizedBox(height: MirasSpacing.sm),
                MirasButton(
                  label: strings.galleryTitle,
                  variant: MirasButtonVariant.text,
                  expand: true,
                  onPressed: () => context.go(AppRoutes.gallery),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
