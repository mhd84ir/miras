import 'package:flutter/foundation.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';

/// An [Exercise] with every content reference it needs already resolved,
/// so widgets and answer checking never touch repositories mid-lesson.
@immutable
class LoadedExercise {
  const LoadedExercise({
    required this.exercise,
    this.verse,
    this.vocab,
    this.retelling,
    this.matchingItems = const [],
  });

  final Exercise exercise;

  /// Resolved for cloze / hemistichAssembly / verseIntro.
  final Verse? verse;

  /// Resolved for vocabIntro / listening / multipleChoice with vocabId.
  final VocabItem? vocab;

  /// Resolved for storySection.
  final RetellingSection? retelling;

  /// Resolved for matching (in `pairs` order).
  final List<VocabItem> matchingItems;

  ExercisePrompt get prompt => exercise.prompt;

  /// The exact tile sequence an assembly answer must reproduce.
  List<String> get assemblyTargetTokens {
    final p = prompt as HemistichAssemblyPrompt;
    return verse!.tokensOf(p.hemistich);
  }

  /// Whether [answer] is correct for this exercise. Throws [StateError] on
  /// an answer type that does not fit the prompt — that is a programming
  /// error in the widget, not user input.
  bool check(ExerciseAnswer answer) {
    return switch ((prompt, answer)) {
      (VocabIntroPrompt(), Acknowledged()) ||
      (VerseIntroPrompt(), Acknowledged()) ||
      (StorySectionPrompt(), Acknowledged()) => true,
      (final MultipleChoicePrompt p, ChoiceAnswer(:final index)) =>
        index == p.correctIndex,
      (final ComprehensionPrompt p, ChoiceAnswer(:final index)) =>
        index == p.correctIndex,
      (final ClozePrompt p, ChoiceAnswer(:final index)) =>
        index == p.correctIndex,
      (final ListeningPrompt p, ChoiceAnswer(:final index)) =>
        index == p.correctIndex,
      (HemistichAssemblyPrompt(), TilesAnswer(:final tiles)) => listEquals(
        tiles,
        assemblyTargetTokens,
      ),
      (final SequencingPrompt p, OrderAnswer(:final ids)) => listEquals(
        ids,
        p.correctOrder,
      ),
      (MatchingPrompt(), MatchAnswer(:final wrongAttempts)) =>
        wrongAttempts == 0,
      _ => throw StateError(
        '${answer.runtimeType} is not a valid answer for '
        '${prompt.runtimeType}',
      ),
    };
  }
}
