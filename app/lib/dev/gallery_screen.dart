import 'package:flutter/material.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/core/widgets/couplet_view.dart';
import 'package:miras/core/widgets/miras_button.dart';

/// Development-only design-system gallery: renders every token and component
/// for visual review, including the verse-face comparison (M0 exit criterion).
/// Registered only in debug builds (see app_router.dart).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  // Verse-face candidates rendered against the same couplet. The chosen
  // family becomes MirasTextStyles.verseFontFamily; the rest are removed.
  static const _verseFaceCandidates = ['Vazirmatn', 'Amiri', 'NotoNaskhArabic'];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.mirasColors;

    return Scaffold(
      appBar: AppBar(title: Text(strings.galleryTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(MirasSpacing.screenMargin),
        children: [
          _section(context, 'رنگ‌ها', _ColorGrid(colors: colors)),
          _section(context, 'گونه‌شناسی متن', const _TypeScale()),
          _section(context, 'دکمه‌ها', const _Buttons()),
          _section(context, 'بیت — مقایسهٔ قلم مصراع', const _VerseFaces()),
          _section(context, 'اعداد فارسی', const _Numbers()),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: MirasSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors});

  final MirasColors colors;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color)>[
      ('firoozeh', colors.firoozeh),
      ('lajvard', colors.lajvard),
      ('zarrin', colors.zarrin),
      ('anari', colors.anari),
      ('sabz', colors.sabz),
      ('atash', colors.atash),
      ('background', colors.background),
      ('surface', colors.surface),
      ('surfaceVariant', colors.surfaceVariant),
      ('ink', colors.ink),
      ('inkMuted', colors.inkMuted),
      ('hairline', colors.hairline),
    ];

    return Wrap(
      spacing: MirasSpacing.sm,
      runSpacing: MirasSpacing.sm,
      children: [
        for (final (name, color) in entries)
          Column(
            children: [
              Container(
                width: 72,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(MirasRadii.sm),
                  border: Border.all(color: colors.hairline),
                ),
              ),
              const SizedBox(height: MirasSpacing.xs),
              Text(name, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  static const _sample = 'چو ایران نباشد تن من مباد';

  @override
  Widget build(BuildContext context) {
    final styles = <(String, TextStyle)>[
      ('display', MirasTextStyles.display),
      ('headline', MirasTextStyles.headline),
      ('title', MirasTextStyles.title),
      ('body', MirasTextStyles.body),
      ('bodySmall', MirasTextStyles.bodySmall),
      ('caption', MirasTextStyles.caption),
    ];
    final colors = context.mirasColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in styles)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _sample,
                    style: style.copyWith(color: colors.ink),
                  ),
                ),
                Text(name, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    void noop() {}

    return Wrap(
      spacing: MirasSpacing.sm,
      runSpacing: MirasSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MirasButton(label: 'اصلی', onPressed: noop),
        MirasButton(
          label: 'ثانویه',
          variant: MirasButtonVariant.secondary,
          onPressed: noop,
        ),
        MirasButton(
          label: 'متنی',
          variant: MirasButtonVariant.text,
          onPressed: noop,
        ),
        const MirasButton(label: 'غیرفعال', onPressed: null),
      ],
    );
  }
}

class _VerseFaces extends StatelessWidget {
  const _VerseFaces();

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;

    return Column(
      children: [
        for (final family in GalleryScreen._verseFaceCandidates)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(MirasRadii.md),
                border: Border.all(color: colors.hairline),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(MirasSpacing.md),
                child: Column(
                  children: [
                    Text(family, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: MirasSpacing.sm),
                    CoupletView(
                      hemistich1: 'به نام خداوند جان و خرد',
                      hemistich2: 'کزین برتر اندیشه برنگذرد',
                      style: MirasTextStyles.verse.copyWith(fontFamily: family),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers();

  @override
  Widget build(BuildContext context) {
    final samples = [
      PersianText.number(0),
      PersianText.number(42),
      PersianText.number(1234567),
      PersianText.digits('12:34'),
    ];

    return Text(
      samples.join('  ·  '),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
