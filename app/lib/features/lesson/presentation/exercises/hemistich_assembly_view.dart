import 'dart:math';

import 'package:flutter/material.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

/// hemistichAssembly: arrange shuffled word tiles into the correct مصراع.
/// The other hemistich is shown as context above the board.
class HemistichAssemblyView extends StatefulWidget {
  const HemistichAssemblyView({
    required this.loaded,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;

  /// Called with the current tile arrangement (empty = nothing placed).
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<HemistichAssemblyView> createState() => _HemistichAssemblyViewState();
}

class _HemistichAssemblyViewState extends State<HemistichAssemblyView> {
  /// Bank tiles are identified by index (tokens can repeat, e.g. «و»).
  late final List<String> _bank;
  final _placed = <int>[];

  @override
  void initState() {
    super.initState();
    final prompt = widget.loaded.prompt as HemistichAssemblyPrompt;
    _bank = [...widget.loaded.assemblyTargetTokens, ...prompt.distractors]
      // Seeded by exercise id: stable order per exercise run and in tests.
      ..shuffle(Random(widget.loaded.exercise.id.hashCode));
  }

  void _toggle(int bankIndex) {
    if (!widget.enabled) return;
    setState(() {
      if (_placed.contains(bankIndex)) {
        _placed.remove(bankIndex);
      } else {
        _placed.add(bankIndex);
      }
    });
    widget.onChanged([for (final i in _placed) _bank[i]]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);
    final prompt = widget.loaded.prompt as HemistichAssemblyPrompt;
    final contextLine = prompt.hemistich == 1
        ? widget.loaded.verse!.hemistich2
        : widget.loaded.verse!.hemistich1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.assemblyInstruction,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.md),
        Text(
          contextLine,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: MirasTextStyles.verse.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        // Answer area.
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsetsDirectional.all(MirasSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(MirasRadii.md),
          ),
          child: Wrap(
            spacing: MirasSpacing.sm,
            runSpacing: MirasSpacing.sm,
            children: [
              for (final i in _placed)
                _Tile(
                  label: _bank[i],
                  onTap: widget.enabled ? () => _toggle(i) : null,
                  placed: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: MirasSpacing.lg),
        // Bank.
        Wrap(
          spacing: MirasSpacing.sm,
          runSpacing: MirasSpacing.sm,
          children: [
            for (final (i, token) in _bank.indexed)
              if (!_placed.contains(i))
                _Tile(
                  label: token,
                  onTap: widget.enabled ? () => _toggle(i) : null,
                  placed: false,
                ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap, required this.placed});

  final String label;
  final VoidCallback? onTap;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    return Material(
      color: placed ? colors.firoozeh : colors.surface,
      borderRadius: BorderRadius.circular(MirasRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MirasRadii.sm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MirasRadii.sm),
            border: Border.all(
              color: placed ? colors.firoozeh : colors.hairline,
            ),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: MirasSpacing.md,
            vertical: MirasSpacing.sm,
          ),
          child: Text(
            label,
            style: MirasTextStyles.body.copyWith(
              color: placed ? Colors.white : colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
