import 'package:flutter/material.dart';

import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';

/// Renders one بیت (couplet) as its two hemistichs (مصراع).
///
/// Wide layouts show the hemistichs side by side (traditional two-column verse
/// setting); narrow layouts stack them. Verse text is never wrapped as prose.
class CoupletView extends StatelessWidget {
  const CoupletView({
    required this.hemistich1,
    required this.hemistich2,
    this.style,
    super.key,
  });

  final String hemistich1;
  final String hemistich2;

  /// Overrides [MirasTextStyles.verse] — used by the design-system gallery to
  /// compare verse-face candidates.
  final TextStyle? style;

  static const _sideBySideMinWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? MirasTextStyles.verse).copyWith(
      color: context.mirasColors.ink,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hemistichs = [
          Text(
            hemistich1,
            style: effectiveStyle,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          Text(
            hemistich2,
            style: effectiveStyle,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ];

        if (constraints.maxWidth >= _sideBySideMinWidth) {
          return Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(child: hemistichs[0]),
              const SizedBox(width: MirasSpacing.xl),
              Expanded(child: hemistichs[1]),
            ],
          );
        }

        return Column(
          children: [
            hemistichs[0],
            const SizedBox(height: MirasSpacing.xs),
            hemistichs[1],
          ],
        );
      },
    );
  }
}
