import 'package:flutter/material.dart';

import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';

enum MirasButtonVariant { primary, secondary, text }

/// Design-system button (DESIGN_SYSTEM.md §7): pill shape, 52dp min height,
/// subtle press-scale feedback.
class MirasButton extends StatefulWidget {
  const MirasButton({
    required this.label,
    required this.onPressed,
    this.variant = MirasButtonVariant.primary,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final MirasButtonVariant variant;

  /// Stretch to the available width (main CTAs).
  final bool expand;

  @override
  State<MirasButton> createState() => _MirasButtonState();
}

class _MirasButtonState extends State<MirasButton> {
  final _states = WidgetStatesController();
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(() {
      final pressed = _states.value.contains(WidgetState.pressed);
      if (pressed != _pressed) setState(() => _pressed = pressed);
    });
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;

    final style =
        switch (widget.variant) {
          // action/onAction (not raw firoozeh): label contrast is WCAG-AA,
          // enforced by test/a11y/a11y_guidelines_test.dart.
          MirasButtonVariant.primary => FilledButton.styleFrom(
            backgroundColor: colors.action,
            foregroundColor: colors.onAction,
            disabledBackgroundColor: colors.surfaceVariant,
            disabledForegroundColor: colors.inkMuted,
          ),
          MirasButtonVariant.secondary => FilledButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.action,
            disabledForegroundColor: colors.inkMuted,
            side: BorderSide(color: colors.hairline, width: 1.5),
          ),
          MirasButtonVariant.text => FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.action,
            disabledForegroundColor: colors.inkMuted,
          ),
        }.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsetsDirectional.symmetric(horizontal: MirasSpacing.lg),
          ),
          textStyle: const WidgetStatePropertyAll(MirasTextStyles.button),
          elevation: const WidgetStatePropertyAll(0),
        );

    final button = FilledButton(
      onPressed: widget.onPressed,
      style: style,
      statesController: _states,
      child: Text(widget.label),
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}
