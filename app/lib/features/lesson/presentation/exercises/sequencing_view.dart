import 'dart:math';

import 'package:flutter/material.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';
import 'package:miras/core/theme/miras_colors.dart';
import 'package:miras/core/theme/miras_spacing.dart';
import 'package:miras/core/theme/miras_text_styles.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

/// sequencing: drag story events into chronological order.
class SequencingView extends StatefulWidget {
  const SequencingView({
    required this.loaded,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final LoadedExercise loaded;

  /// Called with event ids in the user's current order.
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<SequencingView> createState() => _SequencingViewState();
}

class _SequencingViewState extends State<SequencingView> {
  late final List<SequencingEvent> _events;

  @override
  void initState() {
    super.initState();
    final prompt = widget.loaded.prompt as SequencingPrompt;
    _events = [...prompt.events]
      ..shuffle(Random(widget.loaded.exercise.id.hashCode));
    // Authored order often IS the correct order — never present it solved.
    if (_currentIds().join() == prompt.correctOrder.join()) {
      _events.add(_events.removeAt(0));
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onChanged(_currentIds()),
    );
  }

  List<String> _currentIds() => [for (final e in _events) e.id];

  @override
  Widget build(BuildContext context) {
    final colors = context.mirasColors;
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.sequencingInstruction,
          style: MirasTextStyles.bodySmall.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: MirasSpacing.md),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _events.length,
          // onReorderItem already delivers the index adjusted for removal.
          onReorderItem: (oldIndex, newIndex) {
            if (!widget.enabled) return;
            setState(() {
              _events.insert(newIndex, _events.removeAt(oldIndex));
            });
            widget.onChanged(_currentIds());
          },
          itemBuilder: (context, index) {
            final event = _events[index];
            return Padding(
              key: ValueKey(event.id),
              padding: const EdgeInsetsDirectional.only(
                bottom: MirasSpacing.sm,
              ),
              child: ReorderableDragStartListener(
                index: index,
                enabled: widget.enabled,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(MirasRadii.md),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(MirasSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            PersianText.number(index + 1),
                            style: MirasTextStyles.caption.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: MirasSpacing.sm),
                        Expanded(
                          child: Text(
                            event.text,
                            style: MirasTextStyles.body.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                        Icon(Icons.drag_indicator, color: colors.inkMuted),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
