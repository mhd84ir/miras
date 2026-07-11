import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:miras/core/audio/audio_service.dart';
import 'package:miras/core/audio/sfx_service.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/haptics/haptics_service.dart';
import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/lesson/application/lesson_controller.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';
import 'package:miras/features/lesson/presentation/exercises/choice_views.dart';
import 'package:miras/features/lesson/presentation/exercises/hemistich_assembly_view.dart';
import 'package:miras/features/lesson/presentation/exercises/matching_view.dart';
import 'package:miras/features/lesson/presentation/exercises/presentation_views.dart';
import 'package:miras/features/lesson/presentation/exercises/sequencing_view.dart';
import 'package:miras/features/lesson/presentation/lesson_results_view.dart';
import 'package:miras/features/lesson/presentation/widgets/exercise_scaffold.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  /// The in-progress answer for the current exercise; null = not submittable.
  ExerciseAnswer? _draft;
  int _draftIndex = -1;

  /// The completion sound plays once per completion (retry resets it).
  bool _completeSfxPlayed = false;

  @override
  Widget build(BuildContext context) {
    final provider = lessonControllerProvider(widget.lessonId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final strings = AppLocalizations.of(context);

    // Entering a new exercise invalidates the previous draft.
    if (state.index != _draftIndex) {
      _draft = null;
      _draftIndex = state.index;
    }

    switch (state.phase) {
      case LessonPhase.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case LessonPhase.completed:
        if (!_completeSfxPlayed) {
          _completeSfxPlayed = true;
          unawaited(ref.read(sfxServiceProvider).play(Sfx.complete));
          unawaited(ref.read(hapticsServiceProvider).celebrate());
        }
        return LessonResultsView(
          state: state,
          onExit: () => context.go('/'),
          onRetry: () => ref.invalidate(provider),
          onGoReview: () => context.go('/review'),
        );

      case LessonPhase.question || LessonPhase.feedback:
        _completeSfxPlayed = false;
        final current = state.current!;
        final isQuestion = state.phase == LessonPhase.question;
        final isPresentation = current.prompt.isPresentation;

        return ExerciseScaffold(
          progress: state.progress,
          hearts: state.hearts,
          onClose: () => context.go('/'),
          body: KeyedSubtree(
            key: ValueKey('${current.exercise.id}-${state.index}'),
            child: _exerciseView(current, enabled: isQuestion),
          ),
          footer: ExerciseFooter(
            feedback: isQuestion
                ? null
                : FeedbackBanner(
                    correct: state.lastCorrect!,
                    title: state.lastCorrect!
                        ? strings.lessonCorrect
                        : strings.lessonWrongTitle,
                    detail: state.lastCorrect!
                        ? null
                        : _correctAnswerText(current),
                  ),
            button: isQuestion
                ? MirasButton(
                    label: isPresentation
                        ? strings.lessonContinue
                        : strings.lessonCheck,
                    expand: true,
                    onPressed: isPresentation || _draft != null
                        ? () async {
                            await controller.submit(
                              isPresentation ? const Acknowledged() : _draft!,
                            );
                            if (!isPresentation) {
                              await _answerFeedback(ref, widget.lessonId);
                            }
                          }
                        : null,
                  )
                : MirasButton(
                    label: strings.lessonContinue,
                    expand: true,
                    onPressed: controller.next,
                  ),
          ),
        );
    }
  }

  Widget _exerciseView(LoadedExercise current, {required bool enabled}) {
    void setDraft(ExerciseAnswer? answer) => setState(() => _draft = answer);

    return switch (current.prompt) {
      VocabIntroPrompt() => VocabIntroView(loaded: current),
      VerseIntroPrompt() => VerseIntroView(
        loaded: current,
        playing: ref.watch(audioPlayingProvider).value ?? false,
        onPlay: switch (current.verse?.audioAsset) {
          null => null,
          final asset => () => unawaited(
            ref.read(audioServiceProvider).playAsset(asset),
          ),
        },
      ),
      StorySectionPrompt() => StorySectionView(loaded: current),
      MultipleChoicePrompt() || ComprehensionPrompt() => QuestionChoiceView(
        loaded: current,
        selected: (_draft as ChoiceAnswer?)?.index,
        onSelect: (i) => setDraft(ChoiceAnswer(i)),
        enabled: enabled,
      ),
      ClozePrompt() => ClozeView(
        loaded: current,
        selected: (_draft as ChoiceAnswer?)?.index,
        onSelect: (i) => setDraft(ChoiceAnswer(i)),
        enabled: enabled,
      ),
      ListeningPrompt() => ListeningView(
        loaded: current,
        selected: (_draft as ChoiceAnswer?)?.index,
        onSelect: (i) => setDraft(ChoiceAnswer(i)),
        enabled: enabled,
        playing: ref.watch(audioPlayingProvider).value ?? false,
        onPlay: switch (current.vocab?.audioAsset) {
          null => null,
          final asset => () => unawaited(
            ref.read(audioServiceProvider).playAsset(asset),
          ),
        },
      ),
      HemistichAssemblyPrompt() => HemistichAssemblyView(
        loaded: current,
        onChanged: (tiles) =>
            setDraft(tiles.isEmpty ? null : TilesAnswer(tiles)),
        enabled: enabled,
      ),
      SequencingPrompt() => SequencingView(
        loaded: current,
        onChanged: (ids) => setDraft(OrderAnswer(ids)),
        enabled: enabled,
      ),
      MatchingPrompt() => MatchingView(
        loaded: current,
        onChanged: setDraft,
        enabled: enabled,
      ),
    };
  }

  /// Physical + audible answer confirmation (DESIGN_SYSTEM.md §5); each is a
  /// no-op when the device or the user's settings say so.
  Future<void> _answerFeedback(WidgetRef ref, String lessonId) async {
    final correct = ref.read(lessonControllerProvider(lessonId)).lastCorrect;
    if (correct == null) return;
    unawaited(
      ref.read(sfxServiceProvider).play(correct ? Sfx.correct : Sfx.wrong),
    );
    final haptics = ref.read(hapticsServiceProvider);
    await (correct ? haptics.success() : haptics.failure());
  }

  String? _correctAnswerText(LoadedExercise current) {
    return switch (current.prompt) {
      MultipleChoicePrompt(:final options, :final correctIndex) ||
      ComprehensionPrompt(:final options, :final correctIndex) ||
      ClozePrompt(:final options, :final correctIndex) ||
      ListeningPrompt(
        :final options,
        :final correctIndex,
      ) => options[correctIndex],
      HemistichAssemblyPrompt() => current.assemblyTargetTokens.join(' '),
      // Order-based and matching feedback would be noise; the board itself
      // already showed what went wrong.
      SequencingPrompt() || MatchingPrompt() => null,
      VocabIntroPrompt() || VerseIntroPrompt() || StorySectionPrompt() => null,
    };
  }
}
