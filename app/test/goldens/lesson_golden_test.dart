import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/core/widgets/miras_button.dart';
import 'package:miras/features/home_path/application/path_providers.dart';
import 'package:miras/features/home_path/presentation/widgets/lesson_path_node.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';
import 'package:miras/features/lesson/presentation/exercises/choice_views.dart';
import 'package:miras/features/lesson/presentation/exercises/hemistich_assembly_view.dart';
import 'package:miras/features/lesson/presentation/exercises/matching_view.dart';
import 'package:miras/features/lesson/presentation/exercises/presentation_views.dart';
import 'package:miras/features/lesson/presentation/widgets/exercise_scaffold.dart';

import '../helpers/fakes.dart';
import 'golden_harness.dart';

LoadedExercise exerciseWith(
  ExercisePrompt prompt, {
  Verse? verse,
  VocabItem? vocab,
  List<VocabItem> matchingItems = const [],
}) {
  return LoadedExercise(
    exercise: Exercise(
      id: 'zahak.l02.e01',
      lessonId: 'zahak.l02',
      position: 0,
      prompt: prompt,
      difficulty: 1,
    ),
    verse: verse,
    vocab: vocab,
    matchingItems: matchingItems,
  );
}

void main() {
  testWidgets('vocab intro', (tester) async {
    await pumpGolden(
      tester,
      VocabIntroView(
        loaded: exerciseWith(
          const VocabIntroPrompt(vocabId: 'vocab.dadkhah'),
          vocab: Fixtures.vocab,
        ),
      ),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_vocab_intro.png'),
    );
  });

  testWidgets('verse intro', (tester) async {
    await pumpGolden(
      tester,
      VerseIntroView(
        loaded: exerciseWith(
          const VerseIntroPrompt(verseId: 'zahak.v010'),
          verse: Fixtures.verse,
        ),
      ),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_verse_intro.png'),
    );
  });

  testWidgets('cloze with a selected option', (tester) async {
    await pumpGolden(
      tester,
      ClozeView(
        loaded: exerciseWith(
          const ClozePrompt(
            verseId: 'zahak.v010',
            hemistich: 1,
            blankToken: 5,
            options: ['شهریار', 'دادخواه', 'خوالیگر'],
            correctIndex: 0,
          ),
          verse: Fixtures.verse,
        ),
        selected: 0,
        onSelect: (_) {},
        enabled: true,
      ),
      surfaceSize: const Size(400, 620),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_cloze_selected.png'),
    );
  });

  testWidgets('hemistich assembly board', (tester) async {
    await pumpGolden(
      tester,
      HemistichAssemblyView(
        loaded: exerciseWith(
          const HemistichAssemblyPrompt(
            verseId: 'zahak.v010',
            hemistich: 2,
            distractors: ['درفش'],
          ),
          verse: Fixtures.verse,
        ),
        onChanged: (_) {},
        enabled: true,
      ),
      surfaceSize: const Size(400, 560),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_assembly.png'),
    );
  });

  testWidgets('matching board', (tester) async {
    await pumpGolden(
      tester,
      MatchingView(
        loaded: exerciseWith(
          const MatchingPrompt(vocabIds: ['vocab.dadkhah', 'vocab.derafsh']),
          matchingItems: [Fixtures.vocab, Fixtures.vocab2],
        ),
        onChanged: (_) {},
        enabled: true,
      ),
      surfaceSize: const Size(400, 500),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_matching.png'),
    );
  });

  testWidgets('verse intro — narrated', (tester) async {
    await pumpGolden(
      tester,
      VerseIntroView(
        loaded: exerciseWith(
          const VerseIntroPrompt(verseId: 'zahak.v010'),
          verse: Fixtures.verse,
        ),
        onPlay: () {},
      ),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_verse_intro_narrated.png'),
    );
  });

  testWidgets('listening exercise', (tester) async {
    await pumpGolden(
      tester,
      ListeningView(
        loaded: exerciseWith(
          const ListeningPrompt(
            vocabId: 'vocab.derafsh',
            options: ['درفش', 'درویش', 'فرش'],
            correctIndex: 0,
          ),
          vocab: Fixtures.vocab2,
        ),
        selected: null,
        onSelect: (_) {},
        enabled: true,
        playing: false,
        onPlay: () {},
      ),
      surfaceSize: const Size(400, 560),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_listening.png'),
    );
  });

  testWidgets('listening exercise — playing state', (tester) async {
    await pumpGolden(
      tester,
      ListeningView(
        loaded: exerciseWith(
          const ListeningPrompt(
            vocabId: 'vocab.derafsh',
            options: ['درفش', 'درویش', 'فرش'],
            correctIndex: 0,
          ),
          vocab: Fixtures.vocab2,
        ),
        selected: null,
        onSelect: (_) {},
        enabled: true,
        playing: true,
        onPlay: () {},
      ),
      surfaceSize: const Size(400, 560),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/exercise_listening_playing.png'),
    );
  });

  testWidgets('feedback footer — wrong answer', (tester) async {
    await pumpGolden(
      tester,
      ExerciseFooter(
        feedback: const FeedbackBanner(
          correct: false,
          title: 'پاسخ درست:',
          detail: 'بر او سالیان انجمن شد هزار',
        ),
        button: MirasButton(label: 'ادامه', expand: true, onPressed: () {}),
      ),
      surfaceSize: const Size(400, 260),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/feedback_footer_wrong.png'),
    );
  });

  testWidgets('lesson path nodes in all three states', (tester) async {
    await pumpGolden(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LessonPathNode(
            node: const LessonNode(
              lesson: Lesson(
                id: 'zahak.l01',
                chapterId: 'zahak',
                position: 0,
                type: LessonType.vocab,
                title: 'واژگان ۱ — مرداس و ابلیس',
              ),
              status: LessonNodeStatus.completed,
              stars: 2,
            ),
            onTap: () {},
          ),
          LessonPathNode(
            node: const LessonNode(
              lesson: Lesson(
                id: 'zahak.l02',
                chapterId: 'zahak',
                position: 1,
                type: LessonType.practice,
                title: 'تمرین واژگان ۱',
              ),
              status: LessonNodeStatus.available,
            ),
            onTap: () {},
          ),
          const LessonPathNode(
            node: LessonNode(
              lesson: Lesson(
                id: 'zahak.l03',
                chapterId: 'zahak',
                position: 2,
                type: LessonType.verses,
                title: 'ابیات ۱ — فریب ابلیس',
              ),
              status: LessonNodeStatus.locked,
            ),
            onTap: null,
          ),
        ],
      ),
      surfaceSize: const Size(400, 360),
    );
    await expectLater(
      goldenSubject(),
      matchesGoldenFile('goldens/lesson_path_nodes.png'),
    );
  });
}
