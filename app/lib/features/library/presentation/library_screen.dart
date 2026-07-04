import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/home_path/application/path_providers.dart';

/// Free-reading entry point: pick a chapter to read its verses and retelling.
/// Reading never costs hearts (PRD product principle 2).
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;
    final chapters = ref.watch(chaptersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.navLibrary)),
      body: chapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) => ListView(
          padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
          children: [
            for (final chapter in list)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: MirasSpacing.md,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(MirasRadii.lg),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MirasRadii.lg),
                    onTap: () => context.push('/library/${chapter.id}'),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(MirasSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: MirasTextStyles.title.copyWith(
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: MirasSpacing.xs),
                          Text(
                            chapter.summary,
                            style: MirasTextStyles.bodySmall.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
