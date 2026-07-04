import 'package:flutter/foundation.dart';

/// A user's answer to an exercise. Which subtype is valid depends on the
/// exercise's prompt type — see `LoadedExercise.check`.
sealed class ExerciseAnswer {
  const ExerciseAnswer();
}

/// Tapping "continue" on a presentation exercise (vocab/verse/story intro).
class Acknowledged extends ExerciseAnswer {
  const Acknowledged();
}

/// Selected option index: multipleChoice, comprehension, cloze, listening.
@immutable
class ChoiceAnswer extends ExerciseAnswer {
  const ChoiceAnswer(this.index);
  final int index;
}

/// Tiles in the order the user arranged them: hemistichAssembly.
@immutable
class TilesAnswer extends ExerciseAnswer {
  const TilesAnswer(this.tiles);
  final List<String> tiles;
}

/// Event ids in the user's chosen order: sequencing.
@immutable
class OrderAnswer extends ExerciseAnswer {
  const OrderAnswer(this.ids);
  final List<String> ids;
}

/// Matching board outcome: the board always gets completed; correctness
/// means completing it without any wrong pairing attempts.
@immutable
class MatchAnswer extends ExerciseAnswer {
  const MatchAnswer({required this.wrongAttempts});
  final int wrongAttempts;
}
