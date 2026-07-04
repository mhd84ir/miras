import 'dart:math';

import 'package:flutter/material.dart';

import 'package:miras/core/content/models.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

/// matching: tap a word, tap a meaning; matched pairs lock in. The board is
/// "ready to check" once every pair is matched — correctness means zero
/// wrong pairings along the way (see MatchAnswer).
class MatchingView extends StatefulWidget {
  const MatchingView({
    required this.loaded,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;

  /// Called with the board result when complete, null while in progress.
  final ValueChanged<MatchAnswer?> onChanged;
  final bool enabled;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  late final List<VocabItem> _words;
  late final List<VocabItem> _meanings;

  String? _selectedWordId;
  String? _flashWrongId;
  final _matched = <String>{};
  var _wrongAttempts = 0;

  @override
  void initState() {
    super.initState();
    final seed = widget.loaded.exercise.id.hashCode;
    _words = [...widget.loaded.matchingItems]..shuffle(Random(seed));
    _meanings = [...widget.loaded.matchingItems]..shuffle(Random(seed + 1));
  }

  void _tapWord(VocabItem item) {
    if (!widget.enabled || _matched.contains(item.id)) return;
    setState(() => _selectedWordId = item.id);
  }

  void _tapMeaning(VocabItem item) {
    final selected = _selectedWordId;
    if (!widget.enabled || selected == null || _matched.contains(item.id)) {
      return;
    }
    setState(() {
      if (item.id == selected) {
        _matched.add(item.id);
        _selectedWordId = null;
        if (_matched.length == _words.length) {
          widget.onChanged(MatchAnswer(wrongAttempts: _wrongAttempts));
        }
      } else {
        _wrongAttempts++;
        _flashWrongId = item.id;
        _selectedWordId = null;
      }
    });
    if (_flashWrongId != null) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _flashWrongId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.matchingInstruction,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final item in _words)
                    _MatchTile(
                      label: item.word,
                      state: _tileState(item.id, isWordColumn: true),
                      onTap: () => _tapWord(item),
                    ),
                ],
              ),
            ),
            const SizedBox(width: MirasSpacing.md),
            Expanded(
              child: Column(
                children: [
                  for (final item in _meanings)
                    _MatchTile(
                      label: item.meaning,
                      state: _tileState(item.id, isWordColumn: false),
                      onTap: () => _tapMeaning(item),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  _TileState _tileState(String id, {required bool isWordColumn}) {
    if (_matched.contains(id)) return _TileState.matched;
    if (isWordColumn && _selectedWordId == id) return _TileState.selected;
    if (!isWordColumn && _flashWrongId == id) return _TileState.wrong;
    return _TileState.idle;
  }
}

enum _TileState { idle, selected, matched, wrong }

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final (background, border, foreground) = switch (state) {
      _TileState.idle => (colors.surface, colors.hairline, colors.ink),
      _TileState.selected => (
        colors.firoozeh.withValues(alpha: 0.10),
        colors.firoozeh,
        colors.firoozeh,
      ),
      _TileState.matched => (
        colors.sabz.withValues(alpha: 0.10),
        colors.sabz,
        colors.inkMuted,
      ),
      _TileState.wrong => (
        colors.anari.withValues(alpha: 0.10),
        colors.anari,
        colors.anari,
      ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MirasSpacing.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(MirasRadii.md),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: state == _TileState.matched ? null : onTap,
            borderRadius: BorderRadius.circular(MirasRadii.md),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsetsDirectional.all(MirasSpacing.sm),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: MirasTextStyles.bodySmall.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
