import 'package:content_compiler/src/model/content.dart';

/// Listening exercises whose vocabulary item ended up without generated
/// audio, as `exerciseId → vocabId` strings. The app silently skips such
/// exercises at runtime (docs/DATA_MODEL.md §3), so release builds treat a
/// non-empty result as a failure under `--strict`.
List<String> listeningWithoutAudio(
  ContentBundle bundle,
  Set<String> audioVocabIds,
) => [
  for (final e in bundle.allExercises)
    if (e.type == ExerciseType.listening &&
        !audioVocabIds.contains(e.prompt['vocabId']))
      '${e.id} → ${e.prompt['vocabId']}',
];
