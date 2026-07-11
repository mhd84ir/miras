import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';
import 'package:miras/features/lesson/presentation/exercises/choice_views.dart';
import 'package:miras/features/lesson/presentation/exercises/hemistich_assembly_view.dart';
import 'package:miras/features/lesson/presentation/exercises/matching_view.dart';
import 'package:miras/features/lesson/presentation/exercises/presentation_views.dart';

import '../goldens/golden_harness.dart';
import '../helpers/fakes.dart';

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
  testWidgets('choice view reports the tapped option', (tester) async {
    int? selected;
    await pumpGolden(
      tester,
      QuestionChoiceView(
        loaded: exerciseWith(
          const MultipleChoicePrompt(
            question: 'معنی «درفش» چیست؟',
            options: ['پرچم', 'زنجیر', 'آشپز'],
            correctIndex: 0,
          ),
        ),
        selected: null,
        onSelect: (i) => selected = i,
        enabled: true,
      ),
    );

    await tester.tap(find.text('زنجیر'));
    expect(selected, 1);
  });

  testWidgets('cloze shows a blank, then the chosen word', (tester) async {
    const prompt = ClozePrompt(
      verseId: 'zahak.v010',
      hemistich: 1,
      blankToken: 5,
      options: ['شهریار', 'دادخواه'],
      correctIndex: 0,
    );

    await pumpGolden(
      tester,
      ClozeView(
        loaded: exerciseWith(prompt, verse: Fixtures.verse),
        selected: null,
        onSelect: (_) {},
        enabled: true,
      ),
    );
    expect(find.textContaining('____'), findsOneWidget);

    await pumpGolden(
      tester,
      ClozeView(
        loaded: exerciseWith(prompt, verse: Fixtures.verse),
        selected: 0,
        onSelect: (_) {},
        enabled: true,
      ),
    );
    expect(find.textContaining('چو ضحاک شد بر جهان شهریار'), findsOneWidget);
  });

  testWidgets('assembly reports tiles in tap order and removes on re-tap', (
    tester,
  ) async {
    List<String>? tiles;
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
        onChanged: (t) => tiles = t,
        enabled: true,
      ),
      surfaceSize: const Size(400, 800),
    );

    await tester.tap(find.text('بر').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('او').first);
    await tester.pumpAndSettle();
    expect(tiles, ['بر', 'او']);

    // Re-tapping a placed tile removes it from the answer.
    await tester.tap(find.text('بر').first);
    await tester.pumpAndSettle();
    expect(tiles, ['او']);
  });

  testWidgets('listening auto-plays on entry and replays on tap', (
    tester,
  ) async {
    var plays = 0;
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
        onPlay: () => plays++,
      ),
    );
    expect(plays, 1, reason: 'clip auto-plays once when the exercise appears');

    await tester.tap(find.byIcon(Icons.volume_up));
    expect(plays, 2, reason: 'button replays the clip');
  });

  testWidgets('verse intro auto-plays narration once and replays on tap', (
    tester,
  ) async {
    var plays = 0;
    await pumpGolden(
      tester,
      VerseIntroView(
        loaded: exerciseWith(
          const VerseIntroPrompt(verseId: 'zahak.v010'),
          verse: Fixtures.verse,
        ),
        onPlay: () => plays++,
      ),
      surfaceSize: const Size(400, 800),
    );
    expect(plays, 1, reason: 'auto-played on entry');

    await tester.tap(find.byIcon(Icons.volume_up));
    expect(plays, 2);
  });

  testWidgets('verse intro without pack audio shows no play button', (
    tester,
  ) async {
    await pumpGolden(
      tester,
      VerseIntroView(
        loaded: exerciseWith(
          const VerseIntroPrompt(verseId: 'zahak.v010'),
          verse: Fixtures.verse,
        ),
      ),
      surfaceSize: const Size(400, 800),
    );

    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets(
    'matching completes with zero wrong attempts only when never mismatched',
    (tester) async {
      MatchAnswer? answer;
      await pumpGolden(
        tester,
        MatchingView(
          loaded: exerciseWith(
            const MatchingPrompt(vocabIds: ['vocab.dadkhah', 'vocab.derafsh']),
            matchingItems: [Fixtures.vocab, Fixtures.vocab2],
          ),
          onChanged: (a) => answer = a,
          enabled: true,
        ),
        surfaceSize: const Size(400, 800),
      );

      // One wrong pairing first: دادخواه ↔ پرچم.
      await tester.tap(find.text('دادخواه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('پرچم'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Then match both correctly.
      await tester.tap(find.text('دادخواه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خواهانِ عدالت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('درفش'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('پرچم'));
      await tester.pumpAndSettle();

      expect(answer, isNotNull);
      expect(answer!.wrongAttempts, 1);
    },
  );
}
