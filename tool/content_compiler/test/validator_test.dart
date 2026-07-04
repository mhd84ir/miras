import 'package:content_compiler/content_compiler.dart';
import 'package:test/test.dart';

ChapterContent chapter({
  List<Lesson> lessons = const [],
  List<VocabItem> vocab = const [],
  List<Verse> verses = const [],
  List<RetellingSection> retellings = const [],
}) {
  return ChapterContent(
    id: 'sample',
    position: 1,
    title: 'نمونه',
    subtitle: 'زیرعنوان',
    summary: 'خلاصه',
    sourceFile: 'chapters/sample/chapter.yaml',
    lessons: lessons,
    vocab: vocab,
    verses: verses,
    retellings: retellings,
  );
}

Lesson lesson(List<Exercise> exercises) => Lesson(
  id: 'sample.l01',
  chapterId: 'sample',
  position: 0,
  type: LessonType.practice,
  title: 'تمرین',
  exercises: exercises,
  sourceFile: 'chapters/sample/lessons/01.yaml',
);

Exercise exercise(ExerciseType type, Map<String, Object?> prompt) => Exercise(
  id: 'sample.l01.e01',
  lessonId: 'sample.l01',
  position: 0,
  type: type,
  prompt: prompt,
  sourceFile: 'chapters/sample/lessons/01.yaml',
);

VocabItem vocabItem(String id) => VocabItem(
  id: id,
  chapterId: 'sample',
  word: 'خرد',
  pronunciation: 'kherad',
  meaning: 'عقل و دانایی',
  sourceFile: 'chapters/sample/vocab.yaml',
);

Verse verse(String id) => Verse(
  id: id,
  chapterId: 'sample',
  position: 0,
  hemistich1: 'به نام خداوند جان و خرد',
  hemistich2: 'کزین برتر اندیشه برنگذرد',
  meaning: 'آغاز به نام خداوند',
  sourceFile: 'chapters/sample/verses.yaml',
);

List<ContentIssue> errorsOf(ContentBundle bundle) => Validator(
  bundle,
).validate().where((i) => i.severity == IssueSeverity.error).toList();

void main() {
  test('valid minimal bundle has no errors', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          vocab: [vocabItem('vocab.kherad')],
          verses: [verse('sample.v001')],
          lessons: [
            lesson([
              exercise(ExerciseType.vocabIntro, {'vocabId': 'vocab.kherad'}),
            ]),
          ],
        ),
      ],
    );
    expect(errorsOf(bundle), isEmpty);
  });

  test('rejects unknown references', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          lessons: [
            lesson([
              exercise(ExerciseType.vocabIntro, {'vocabId': 'vocab.ghost'}),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('unknown vocab "vocab.ghost"')),
    );
  });

  test('rejects malformed ids', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          verses: [verse('sample.verse1')],
          lessons: [
            lesson([
              exercise(ExerciseType.verseIntro, {'verseId': 'sample.verse1'}),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('must match "sample.vNNN"')),
    );
  });

  test('cloze: correct option must equal the blanked token', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          verses: [verse('sample.v001')],
          lessons: [
            lesson([
              exercise(ExerciseType.cloze, {
                'verseId': 'sample.v001',
                'hemistich': 1,
                'blankToken': 5, // «خرد»
                'options': ['روان', 'خرد', 'سخن'],
                'correctIndex': 0, // wrong on purpose: «روان» ≠ «خرد»
              }),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('does not equal the blanked token')),
    );
  });

  test('cloze: blankToken out of range is rejected', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          verses: [verse('sample.v001')],
          lessons: [
            lesson([
              exercise(ExerciseType.cloze, {
                'verseId': 'sample.v001',
                'hemistich': 1,
                'blankToken': 99,
                'options': ['خرد', 'روان'],
                'correctIndex': 0,
              }),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('out of range')),
    );
  });

  test('sequencing: correctOrder must be a permutation of event ids', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          lessons: [
            lesson([
              exercise(ExerciseType.sequencing, {
                'events': [
                  {'id': 'a', 'text': 'رویداد یکم'},
                  {'id': 'b', 'text': 'رویداد دوم'},
                  {'id': 'c', 'text': 'رویداد سوم'},
                ],
                'correctOrder': ['a', 'b', 'x'],
              }),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('permutation')),
    );
  });

  test('flags ASCII digits in Persian text as errors', () {
    final v = Verse(
      id: 'sample.v001',
      chapterId: 'sample',
      position: 0,
      hemistich1: 'به نام خداوند جان و خرد',
      hemistich2: 'کزین برتر اندیشه برنگذرد',
      meaning: 'بخش 1 از شاهنامه',
      sourceFile: 'chapters/sample/verses.yaml',
    );
    final bundle = ContentBundle(
      chapters: [
        chapter(
          verses: [v],
          lessons: [
            lesson([
              exercise(ExerciseType.verseIntro, {'verseId': 'sample.v001'}),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('ASCII digits')),
    );
  });

  test('duplicate ids across the bundle are rejected', () {
    final bundle = ContentBundle(
      chapters: [
        chapter(
          vocab: [vocabItem('vocab.kherad'), vocabItem('vocab.kherad')],
          lessons: [
            lesson([
              exercise(ExerciseType.vocabIntro, {'vocabId': 'vocab.kherad'}),
            ]),
          ],
        ),
      ],
    );
    expect(
      errorsOf(bundle).map((e) => e.message),
      contains(contains('duplicate id')),
    );
  });
}
