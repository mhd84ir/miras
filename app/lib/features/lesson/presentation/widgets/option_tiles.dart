import 'package:flutter/material.dart';

import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';

/// Vertical list of selectable answer options — the shared interaction for
/// multiple-choice, comprehension, cloze, and listening exercises.
class OptionTiles extends StatelessWidget {
  const OptionTiles({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
    super.key,
  });

  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Column(
      children: [
        for (final (i, option) in options.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.sm),
            child: _OptionTile(
              label: option,
              isSelected: selected == i,
              onTap: enabled ? () => onSelect(i) : null,
              colors: colors,
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final MirasColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.firoozeh.withValues(alpha: 0.10)
              : colors.surface,
          borderRadius: BorderRadius.circular(MirasRadii.md),
          border: Border.all(
            color: isSelected ? colors.firoozeh : colors.hairline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(MirasRadii.md),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MirasSpacing.md,
                vertical: MirasSpacing.sm,
              ),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                style: MirasTextStyles.body.copyWith(
                  // action, not firoozeh: 16px text needs AA contrast.
                  color: isSelected ? colors.action : colors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
