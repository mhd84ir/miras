import 'package:flutter/material.dart';

import 'package:miras/core/theme/miras_colors.dart';

/// Rounded, animated progress bar (DESIGN_SYSTEM.md §7).
class MirasProgressBar extends StatelessWidget {
  const MirasProgressBar({required this.value, super.key});

  /// 0..1
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => LinearProgressIndicator(
          value: animated,
          minHeight: 12,
          backgroundColor: colors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(colors.firoozeh),
        ),
      ),
    );
  }
}
