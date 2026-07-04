import 'package:flutter/foundation.dart';

/// Typed exercise payloads, parsed from the pack's `prompt_json`
/// (docs/DATA_MODEL.md §3). Parsing is strict: content is compiler-validated,
/// so a malformed prompt here means a pack/app schema mismatch — fail loudly.
sealed class ExercisePrompt {
  const ExercisePrompt();

  static ExercisePrompt fromJson(String type, Map<String, Object?> json) {
    return switch (type) {
      'vocabIntro' => VocabIntroPrompt(vocabId: json.req('vocabId')),
      'verseIntro' => VerseIntroPrompt(verseId: json.req('verseId')),
      'storySection' => StorySectionPrompt(
        retellingId: json.req('retellingId'),
      ),
      'matching' => MatchingPrompt(vocabIds: json.reqStrings('pairs')),
      'multipleChoice' => MultipleChoicePrompt(
        question: json.req('question'),
        options: json.reqStrings('options'),
        correctIndex: json.reqInt('correctIndex'),
        vocabId: json['vocabId'] as String?,
      ),
      'cloze' => ClozePrompt(
        verseId: json.req('verseId'),
        hemistich: json.reqInt('hemistich'),
        blankToken: json.reqInt('blankToken'),
        options: json.reqStrings('options'),
        correctIndex: json.reqInt('correctIndex'),
      ),
      'listening' => ListeningPrompt(
        vocabId: json.req('vocabId'),
        options: json.reqStrings('options'),
        correctIndex: json.reqInt('correctIndex'),
      ),
      'hemistichAssembly' => HemistichAssemblyPrompt(
        verseId: json.req('verseId'),
        hemistich: json.reqInt('hemistich'),
        distractors: json.optStrings('distractors'),
      ),
      'comprehension' => ComprehensionPrompt(
        question: json.req('question'),
        options: json.reqStrings('options'),
        correctIndex: json.reqInt('correctIndex'),
      ),
      'sequencing' => SequencingPrompt(
        events: [
          for (final e in json['events']! as List)
            SequencingEvent(
              id: (e as Map)['id']! as String,
              text: e['text']! as String,
            ),
        ],
        correctOrder: json.reqStrings('correctOrder'),
      ),
      _ => throw ArgumentError('unknown exercise type "$type"'),
    };
  }

  /// Presentation prompts show content and cannot be answered wrong.
  bool get isPresentation => switch (this) {
    VocabIntroPrompt() || VerseIntroPrompt() || StorySectionPrompt() => true,
    _ => false,
  };
}

@immutable
class VocabIntroPrompt extends ExercisePrompt {
  const VocabIntroPrompt({required this.vocabId});
  final String vocabId;
}

@immutable
class VerseIntroPrompt extends ExercisePrompt {
  const VerseIntroPrompt({required this.verseId});
  final String verseId;
}

@immutable
class StorySectionPrompt extends ExercisePrompt {
  const StorySectionPrompt({required this.retellingId});
  final String retellingId;
}

@immutable
class MatchingPrompt extends ExercisePrompt {
  const MatchingPrompt({required this.vocabIds});
  final List<String> vocabIds;
}

@immutable
class MultipleChoicePrompt extends ExercisePrompt {
  const MultipleChoicePrompt({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.vocabId,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? vocabId;
}

@immutable
class ClozePrompt extends ExercisePrompt {
  const ClozePrompt({
    required this.verseId,
    required this.hemistich,
    required this.blankToken,
    required this.options,
    required this.correctIndex,
  });

  final String verseId;
  final int hemistich;
  final int blankToken;
  final List<String> options;
  final int correctIndex;
}

@immutable
class ListeningPrompt extends ExercisePrompt {
  const ListeningPrompt({
    required this.vocabId,
    required this.options,
    required this.correctIndex,
  });

  final String vocabId;
  final List<String> options;
  final int correctIndex;
}

@immutable
class HemistichAssemblyPrompt extends ExercisePrompt {
  const HemistichAssemblyPrompt({
    required this.verseId,
    required this.hemistich,
    required this.distractors,
  });

  final String verseId;
  final int hemistich;
  final List<String> distractors;
}

@immutable
class ComprehensionPrompt extends ExercisePrompt {
  const ComprehensionPrompt({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

@immutable
class SequencingEvent {
  const SequencingEvent({required this.id, required this.text});
  final String id;
  final String text;
}

@immutable
class SequencingPrompt extends ExercisePrompt {
  const SequencingPrompt({required this.events, required this.correctOrder});
  final List<SequencingEvent> events;
  final List<String> correctOrder;
}

extension on Map<String, Object?> {
  String req(String key) => this[key]! as String;
  int reqInt(String key) => this[key]! as int;
  List<String> reqStrings(String key) => (this[key]! as List).cast<String>();
  List<String> optStrings(String key) =>
      (this[key] as List?)?.cast<String>() ?? const [];
}
