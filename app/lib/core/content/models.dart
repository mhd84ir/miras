import 'package:flutter/foundation.dart';

import 'package:miras/core/content/exercise_prompt.dart';

/// Content entities, read from the content pack (docs/DATA_MODEL.md §1).
/// Immutable and identified by stable string IDs.

@immutable
class Chapter {
  const Chapter({
    required this.id,
    required this.position,
    required this.title,
    required this.subtitle,
    required this.summary,
    this.coverAsset,
  });

  final String id;
  final int position;
  final String title;
  final String subtitle;
  final String summary;
  final String? coverAsset;
}

enum LessonType { vocab, practice, verses, story, review }

@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.type,
    required this.title,
  });

  final String id;
  final String chapterId;
  final int position;
  final LessonType type;
  final String title;
}

@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.lessonId,
    required this.position,
    required this.prompt,
    required this.difficulty,
  });

  final String id;
  final String lessonId;
  final int position;
  final ExercisePrompt prompt;
  final int difficulty;
}

@immutable
class VocabItem {
  const VocabItem({
    required this.id,
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.firstChapterId,
    this.etymology,
    this.audioAsset,
    this.exampleVerseId,
  });

  final String id;
  final String word;
  final String pronunciation;
  final String meaning;
  final String? etymology;
  final String? audioAsset;
  final String? exampleVerseId;
  final String firstChapterId;
}

@immutable
class Verse {
  const Verse({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.hemistich1,
    required this.hemistich2,
    required this.meaning,
    this.interpretation,
    this.audioAsset,
    this.source,
  });

  final String id;
  final String chapterId;
  final int position;
  final String hemistich1;
  final String hemistich2;
  final String meaning;
  final String? interpretation;
  final String? audioAsset;
  final String? source;

  /// Space-separated tokens of a hemistich; the unit used by cloze and
  /// assembly exercises. ZWNJ-joined words are single tokens.
  List<String> tokensOf(int hemistich) =>
      (hemistich == 1 ? hemistich1 : hemistich2).split(' ');
}

@immutable
class RetellingSection {
  const RetellingSection({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.body,
    this.illustrationAsset,
  });

  final String id;
  final String chapterId;
  final int position;
  final String body;
  final String? illustrationAsset;
}
