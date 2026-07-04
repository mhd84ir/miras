import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/lesson/application/lesson_controller.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/review/data/srs_repository.dart';

import '../../helpers/fakes.dart';

const _exercises = [
  Exercise(
    id: 'sample.l01.e01',
    lessonId: 'sample.l01',
    position: 0,
    prompt: VocabIntroPrompt(vocabId: 'vocab.dadkhah'),
    difficulty: 1,
  ),
  Exercise(
    id: 'sample.l01.e02',
    lessonId: 'sample.l01',
    position: 1,
    prompt: MultipleChoicePrompt(
      question: 'معنی «دادخواه» چیست؟',
      options: ['خواهانِ عدالت', 'ستمگر'],
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

void main() {
  late ProviderContainer container;
  late FakeProgressRepository progress;
  late FakeGamificationRepository gamification;
  late FakeSrsRepository srs;

  const lessonId = 'sample.l01';
  final provider = lessonControllerProvider(lessonId);

  setUp(() {
    progress = FakeProgressRepository();
    gamification = FakeGamificationRepository();
    srs = FakeSrsRepository();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          FakeContentRepository(
            exerciseMap: const {lessonId: _exercises},
            vocabMap: const {'vocab.dadkhah': Fixtures.vocab},
          ),
        ),
        progressRepositoryProvider.overrideWithValue(progress),
        gamificationRepositoryProvider.overrideWithValue(gamification),
        srsRepositoryProvider.overrideWithValue(srs),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// First call instantiates the controller — AFTER the test body has had a
  /// chance to arrange fake state (e.g. zero hearts).
  Future<LessonState> loaded() async {
    container.listen(provider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container.read(provider);
  }

  LessonController controller() => container.read(provider.notifier);

  test('loads exercises with the persistent heart count', () async {
    final state = await loaded();
    expect(state.phase, LessonPhase.question);
    expect(state.queue, hasLength(3));
    expect(state.hearts, HeartsEconomy.max);
  });

  test('refuses to start with zero hearts and points to review', () async {
    // Refill clock at "now" so lazy refill cannot resurrect hearts mid-test.
    gamification.heartsState = HeartsState(
      count: 0,
      lastRefillAt: DateTime.now(),
    );
    final state = await loaded();
    expect(state.phase, LessonPhase.completed);
    expect(state.outOfHearts, isTrue);
    expect(state.failed, isTrue);
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

  test('perfect run: 3 stars, completion recorded, XP + streak + SRS cards '
      'awarded', () async {
    await loaded();
    final c = controller();
    await c.submit(const Acknowledged());
    await c.submit(const ChoiceAnswer(0));
    await c.next();
    await c.submit(const ChoiceAnswer(1));
    await c.next();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(provider);
    expect(state.phase, LessonPhase.completed);
    expect(state.result!.stars, 3);
    expect(progress.completions.single.lessonId, lessonId);

    // Gamification side effects.
    expect(gamification.xpEvents.single.amount, 15, reason: 'perfect bonus');
    expect(gamification.streakState.current, 1);
    expect(srs.cards.keys, contains('vocab.dadkhah'));
    expect(gamification.unlocked, contains('first_lesson'));
    expect(gamification.unlocked, contains('perfect_lesson'));
  });

  test('wrong answer spends a persistent heart and re-queues', () async {
    await loaded();
    final c = controller();
    await c.submit(const Acknowledged());

    await c.submit(const ChoiceAnswer(1)); // wrong (correct is 0)
    var state = container.read(provider);
    expect(state.hearts, HeartsEconomy.max - 1);
    expect(gamification.heartsState.count, HeartsEconomy.max - 1);
    expect(state.queue, hasLength(4));

    await c.next();
    await c.submit(const ChoiceAnswer(1)); // e03 correct
    await c.next();
    await c.submit(const ChoiceAnswer(0)); // retry of e02 — correct now
    await c.next();
    await Future<void>.delayed(Duration.zero);

    state = container.read(provider);
    expect(state.phase, LessonPhase.completed);
    expect(state.result!.accuracy, 0.5);
    expect(gamification.xpEvents.single.amount, 10, reason: 'no bonus');
  });

  test('running out of hearts fails without recording completion', () async {
    gamification.heartsState = HeartsState(
      count: 1,
      lastRefillAt: DateTime.now(),
    );
    await loaded();
    final c = controller();
    await c.submit(const Acknowledged());

    await c.submit(const ChoiceAnswer(1)); // wrong → last heart gone
    await c.next();

    final state = container.read(provider);
    expect(state.phase, LessonPhase.completed);
    expect(state.failed, isTrue);
    expect(state.outOfHearts, isTrue);
    expect(progress.completions, isEmpty);
    expect(gamification.xpEvents, isEmpty);
  });
}
