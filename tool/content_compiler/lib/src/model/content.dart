/// In-memory model of authored content, produced by the YAML loader and
/// consumed by the validator and pack writer. Mirrors docs/DATA_MODEL.md §1.
library;

class ContentBundle {
  ContentBundle({required this.chapters});

  final List<ChapterContent> chapters;

  Iterable<VocabItem> get allVocab => chapters.expand((c) => c.vocab);
  Iterable<Verse> get allVerses => chapters.expand((c) => c.verses);
  Iterable<Lesson> get allLessons => chapters.expand((c) => c.lessons);
  Iterable<Exercise> get allExercises => allLessons.expand((l) => l.exercises);
  Iterable<RetellingSection> get allRetellings =>
      chapters.expand((c) => c.retellings);
}

class ChapterContent {
  ChapterContent({
    required this.id,
    required this.position,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.sourceFile,
    this.coverAsset,
    this.lessons = const [],
    this.vocab = const [],
    this.verses = const [],
    this.retellings = const [],
  });

  final String id;
  final int position;
  final String title;
  final String subtitle;
  final String summary;
  final String? coverAsset;
  final List<Lesson> lessons;
  final List<VocabItem> vocab;
  final List<Verse> verses;
  final List<RetellingSection> retellings;

  /// Repo-relative path of chapter.yaml, for error messages.
  final String sourceFile;
}

enum LessonType { vocab, practice, verses, story, review }

class Lesson {
  Lesson({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.type,
    required this.title,
    required this.exercises,
    required this.sourceFile,
  });

  final String id;
  final String chapterId;
  final int position;
  final LessonType type;
  final String title;
  final List<Exercise> exercises;
  final String sourceFile;
}

/// All exercise types. Presentation types (vocabIntro, verseIntro,
/// storySection) render content; the rest are interactive.
enum ExerciseType {
  vocabIntro,
  verseIntro,
  storySection,
  matching,
  multipleChoice,
  cloze,
  listening,
  hemistichAssembly,
  comprehension,
  sequencing,
}

class Exercise {
  Exercise({
    required this.id,
    required this.lessonId,
    required this.position,
    required this.type,
    required this.prompt,
    required this.sourceFile,
    this.difficulty = 1,
  });

  final String id;
  final String lessonId;
  final int position;
  final ExerciseType type;

  /// Type-specific payload, validated per-type; serialized as prompt_json.
  final Map<String, Object?> prompt;
  final int difficulty;
  final String sourceFile;
}

class VocabItem {
  VocabItem({
    required this.id,
    required this.chapterId,
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.sourceFile,
    this.etymology,
    this.exampleVerseId,
  });

  final String id;

  /// Chapter where the word is introduced.
  final String chapterId;
  final String word;

  /// Latin transliteration, e.g. `shahriyār`.
  final String pronunciation;
  final String meaning;
  final String? etymology;
  final String? exampleVerseId;
  final String sourceFile;
}

class Verse {
  Verse({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.hemistich1,
    required this.hemistich2,
    required this.meaning,
    required this.sourceFile,
    this.interpretation,
    this.vocabularyIds = const [],
    this.source,
  });

  final String id;
  final String chapterId;
  final int position;
  final String hemistich1;
  final String hemistich2;

  /// Modern-Persian prose meaning.
  final String meaning;
  final String? interpretation;
  final List<String> vocabularyIds;

  /// Provenance, e.g. `ganjoor:/ferdousi/shahname/zahak/sh1#0`.
  final String? source;
  final String sourceFile;
}

class RetellingSection {
  RetellingSection({
    required this.id,
    required this.chapterId,
    required this.position,
    required this.body,
    required this.sourceFile,
    this.illustrationAsset,
  });

  final String id;
  final String chapterId;
  final int position;
  final String body;
  final String? illustrationAsset;
  final String sourceFile;
}

enum IssueSeverity { error, warning }

/// A validation or normalization finding, pointing at the authored file.
class ContentIssue {
  ContentIssue.error(this.file, this.path, this.message)
    : severity = IssueSeverity.error;
  ContentIssue.warning(this.file, this.path, this.message)
    : severity = IssueSeverity.warning;

  final IssueSeverity severity;

  /// Repo-relative YAML file.
  final String file;

  /// Human-readable location inside the file, e.g. `verses[3].hemistich1`.
  final String path;
  final String message;

  @override
  String toString() {
    final tag = severity == IssueSeverity.error ? 'ERROR' : 'WARN ';
    return '$tag $file · $path · $message';
  }
}
