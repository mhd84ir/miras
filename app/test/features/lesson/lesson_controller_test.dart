import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/content_repository.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/home_path/domain/lesson_progress.dart';
import 'package:miras/features/lesson/application/lesson_controller.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';

class _FakeContent implements ContentRepository {
  static const _vocab = VocabItem(
    id: 'vocab.kherad',
    word: 'خرد',
    pronunciation: 'kherad',
    meaning: 'عقل و دانایی',
    firstChapterId: 'sample',
  );

  static const _exercises = [
    Exercise(
      id: 'sample.l01.e01',
      lessonId: 'sample.l01',
      position: 0,
      prompt: VocabIntroPrompt(vocabId: 'vocab.kherad'),
      difficulty: 1,
    ),
    Exercise(
      id: 'sample.l01.e02',
      lessonId: 'sample.l01',
      position: 1,
      prompt: MultipleChoicePrompt(
        question: 'معنی «خرد» چیست؟',
        options: ['عقل و دانایی', 'کوچک'],
        correctIndex: 0,
      ),
      difficulty: 1,
    ),
    Exercise(
      id: 'sample.l01.e03',
      lessonId: 'sample.l01',
      position: 2,
      prompt: ComprehensionPrompt(
        question: 'کاوه که بود؟',
        options: ['خوالیگر', 'آهنگر'],
        correctIndex: 1,
      ),
      difficulty: 1,
    ),
  ];

  @override
  Future<List<Exercise>> exercisesOf(String lessonId) async => _exercises;

  @override
  Future<VocabItem?> vocab(String id) async => _vocab;

  @override
  Future<List<VocabItem>> vocabByIds(List<String> ids) async => [_vocab];

  @override
  Future<List<Chapter>> chapters() async => [];

  @override
  Future<List<Lesson>> lessonsOf(String chapterId) async => [];

  @override
  Future<Verse?> verse(String id) async => null;

  @override
  Future<RetellingSection?> retelling(String id) async => null;

  @override
  Future<List<Verse>> versesOf(String chapterId) async => [];

  @override
  Future<List<RetellingSection>> retellingsOf(String chapterId) async => [];
}

class _RecordingProgress implements ProgressRepository {
  final completions = <LessonResult>[];
  final attempts = <(String, bool)>[];

  @override
  Future<void> recordCompletion(LessonResult result) async {
    completions.add(result);
  }

  @override
  Future<void> logAttempt({
    required String exerciseId,
    required bool wasCorrect,
    required String lessonSessionId,
  }) async {
    attempts.add((exerciseId, wasCorrect));
  }

  @override
  Stream<Map<String, LessonProgress>> watchAll() => const Stream.empty();
}

void main() {
  late ProviderContainer container;
  late _RecordingProgress progress;

  const lessonId = 'sample.l01';
  final provider = lessonControllerProvider(lessonId);

  setUp(() {
    progress = _RecordingProgress();
    container =
        ProviderContainer(
            overrides: [
              contentRepositoryProvider.overrideWithValue(_FakeContent()),
              progressRepositoryProvider.overrideWithValue(progress),
            ],
          )
          // Keep the autoDispose provider alive for the test's duration.
          ..listen(provider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<LessonState> loaded() async {
    await Future<void>.delayed(Duration.zero);
    return container.read(provider);
  }

  LessonController controller() => container.read(provider.notifier);

  test('loads exercises and starts at the first one', () async {
    final state = await loaded();
    expect(state.phase, LessonPhase.question);
    expect(state.queue, hasLength(3));
    expect(state.current!.exercise.id, 'sample.l01.e01');
    expect(state.hearts, sessionHearts);
  });

  test(
    'presentation exercises advance without feedback or attempt log',
    () async {
      await loaded();
      await controller().submit(const Acknowledged());

      final state = container.read(provider);
      expect(state.phase, LessonPhase.question);
      expect(state.index, 1);
      expect(progress.attempts, isEmpty);
    },
  );

  test('perfect run: 100% accuracy, 3 stars, completion recorded', () async {
    await loaded();
    final c = controller();
    await c.submit(const Acknowledged());
    await c.submit(const ChoiceAnswer(0));
    await c.next();
    await c.submit(const ChoiceAnswer(1));
    await c.next();

    final state = container.read(provider);
    expect(state.phase, LessonPhase.completed);
    expect(state.failed, isFalse);
    expect(state.result!.accuracy, 1.0);
    expect(state.result!.stars, 3);
    expect(progress.completions.single.lessonId, lessonId);
    expect(progress.attempts, hasLength(2));
  });

  test(
    'wrong answer costs a heart, re-queues, and only first try counts',
    () async {
      await loaded();
      final c = controller();
      await c.submit(const Acknowledged());

      await c.submit(const ChoiceAnswer(1)); // wrong (correct is 0)
      var state = container.read(provider);
      expect(state.phase, LessonPhase.feedback);
      expect(state.lastCorrect, isFalse);
      expect(state.hearts, sessionHearts - 1);
      expect(state.queue, hasLength(4)); // re-queued at the end

      await c.next();
      await c.submit(const ChoiceAnswer(1)); // e03 correct
      await c.next();
      await c.submit(const ChoiceAnswer(0)); // retry of e02 — correct now
      await c.next();

      state = container.read(provider);
      expect(state.phase, LessonPhase.completed);
      // 2 interactive exercises, only e03 correct on first try → 50%.
      expect(state.result!.accuracy, 0.5);
      expect(state.result!.stars, 1);
    },
  );

  test(
    'running out of hearts fails the lesson without recording completion',
    () async {
      await loaded();
      final c = controller();
      await c.submit(const Acknowledged());

      for (var i = 0; i < sessionHearts; i++) {
        // e02's correct index is 0, e03's is 1 — always send the wrong one.
        final current = container.read(provider).current!;
        final wrong = current.exercise.id == 'sample.l01.e03' ? 0 : 1;
        await c.submit(ChoiceAnswer(wrong));
        await c.next();
      }

      final state = container.read(provider);
      expect(state.phase, LessonPhase.completed);
      expect(state.failed, isTrue);
      expect(state.result, isNull);
      expect(progress.completions, isEmpty);
    },
  );
}
