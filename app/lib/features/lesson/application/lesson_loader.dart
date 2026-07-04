import 'package:miras/core/content/content_repository.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

/// Resolves a lesson's exercises together with every content entity they
/// reference, so the runner works entirely from memory once started.
class LessonLoader {
  LessonLoader(this._content);

  final ContentRepository _content;

  Future<List<LoadedExercise>> load(String lessonId) async {
    final exercises = await _content.exercisesOf(lessonId);
    final loaded = await Future.wait(
      exercises.map((exercise) async {
        switch (exercise.prompt) {
          case VocabIntroPrompt(:final vocabId):
          case ListeningPrompt(:final vocabId):
            return LoadedExercise(
              exercise: exercise,
              vocab: await _content.vocab(vocabId),
            );
          case MultipleChoicePrompt(:final vocabId):
            return LoadedExercise(
              exercise: exercise,
              vocab: vocabId == null ? null : await _content.vocab(vocabId),
            );
          case VerseIntroPrompt(:final verseId):
          case ClozePrompt(:final verseId):
          case HemistichAssemblyPrompt(:final verseId):
            return LoadedExercise(
              exercise: exercise,
              verse: await _content.verse(verseId),
            );
          case StorySectionPrompt(:final retellingId):
            return LoadedExercise(
              exercise: exercise,
              retelling: await _content.retelling(retellingId),
            );
          case MatchingPrompt(:final vocabIds):
            return LoadedExercise(
              exercise: exercise,
              matchingItems: await _content.vocabByIds(vocabIds),
            );
          case ComprehensionPrompt() || SequencingPrompt():
            return LoadedExercise(exercise: exercise);
        }
      }),
    );
    // Listening needs audio; packs built without TTS have none, and the
    // exercise is silently skipped until audio exists (docs/DATA_MODEL.md §3).
    return loaded
        .where(
          (e) => e.prompt is! ListeningPrompt || e.vocab?.audioAsset != null,
        )
        .toList();
  }
}
