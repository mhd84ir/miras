import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/audio/audio_service.dart';
import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/couplet_view.dart';

// ignore: specify_nonobvious_property_types — riverpod provider types are verbose
final _versesProvider = FutureProvider.family<List<Verse>, String>(
  (ref, chapterId) => ref.watch(contentRepositoryProvider).versesOf(chapterId),
);

// ignore: specify_nonobvious_property_types — riverpod provider types are verbose
final _retellingsProvider =
    FutureProvider.family<List<RetellingSection>, String>(
      (ref, chapterId) =>
          ref.watch(contentRepositoryProvider).retellingsOf(chapterId),
    );

// ignore: specify_nonobvious_property_types — riverpod provider types are verbose
final _narrationCreditsProvider = FutureProvider(
  (ref) async => [
    for (final c in await ref.watch(contentRepositoryProvider).credits())
      if (c.kind == 'narration') c,
  ],
);

/// Reading view for one chapter: verses (with meanings) or the retelling.
class LibraryChapterScreen extends ConsumerStatefulWidget {
  const LibraryChapterScreen({required this.chapterId, super.key});

  final String chapterId;

  @override
  ConsumerState<LibraryChapterScreen> createState() =>
      _LibraryChapterScreenState();
}

class _LibraryChapterScreenState extends ConsumerState<LibraryChapterScreen> {
  var _showVerses = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(strings.libraryVerses)),
            ButtonSegment(value: false, label: Text(strings.libraryStory)),
          ],
          selected: {_showVerses},
          onSelectionChanged: (s) => setState(() => _showVerses = s.first),
        ),
      ),
      body: _showVerses
          ? _VersesList(chapterId: widget.chapterId)
          : _RetellingList(chapterId: widget.chapterId),
    );
  }
}

class _VersesList extends ConsumerWidget {
  const _VersesList({required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final verses = ref.watch(_versesProvider(chapterId));
    final credits = ref.watch(_narrationCreditsProvider).value ?? const [];

    return verses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (list) {
        // خوانش credit (ADR-0011) shows only where narration actually plays.
        final showCredit =
            credits.isNotEmpty && list.any((v) => v.audioAsset != null);
        return ListView.builder(
          padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
          itemCount: list.length + (showCredit ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == list.length) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: MirasSpacing.sm,
                ),
                child: Text(
                  strings.libraryNarrationCredit(
                    // Credits are chapter-scoped rows; names repeat.
                    {for (final c in credits) c.name}.join('، '),
                  ),
                  textAlign: TextAlign.center,
                  style: MirasTextStyles.caption.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              );
            }
            final verse = list[i];
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: MirasSpacing.md,
              ),
              // Material (not DecoratedBox): the tiles' ink must paint on
              // this surface, or Flutter asserts in debug builds.
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MirasRadii.md),
                  side: BorderSide(color: colors.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: MirasSpacing.md,
                    ),
                    leading: verse.audioAsset == null
                        ? null
                        : IconButton(
                            tooltip: strings.libraryPlayNarration,
                            icon: Icon(
                              Icons.play_circle_outline,
                              color: colors.action,
                            ),
                            onPressed: () => ref
                                .read(audioServiceProvider)
                                .playAsset(verse.audioAsset!),
                          ),
                    childrenPadding: const EdgeInsetsDirectional.only(
                      start: MirasSpacing.md,
                      end: MirasSpacing.md,
                      bottom: MirasSpacing.md,
                    ),
                    title: CoupletView(
                      hemistich1: verse.hemistich1,
                      hemistich2: verse.hemistich2,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.meaningLabel,
                        style: MirasTextStyles.caption.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      Text(
                        verse.meaning,
                        style: MirasTextStyles.body.copyWith(color: colors.ink),
                      ),
                      if (verse.interpretation != null) ...[
                        const SizedBox(height: MirasSpacing.sm),
                        Text(
                          strings.interpretationLabel,
                          style: MirasTextStyles.caption.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        Text(
                          verse.interpretation!,
                          style: MirasTextStyles.body.copyWith(
                            color: colors.ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RetellingList extends ConsumerWidget {
  const _RetellingList({required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.mirasColors;
    final sections = ref.watch(_retellingsProvider(chapterId));

    return sections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (list) => ListView.builder(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
        itemCount: list.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.lg),
          child: Text(
            list[i].body,
            style: MirasTextStyles.body.copyWith(color: colors.ink, height: 2),
          ),
        ),
      ),
    );
  }
}
