import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/hearts_economy.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/review/application/review_controller.dart';
import 'package:miras/features/review/data/srs_repository.dart';
import 'package:miras/features/review/domain/srs_card.dart';

import '../../helpers/fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeSrsRepository srs;
  late FakeGamificationRepository gamification;

  setUp(() {
    srs = FakeSrsRepository();
    gamification = FakeGamificationRepository();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(
          FakeContentRepository(
            vocabMap: const {
              'vocab.dadkhah': Fixtures.vocab,
              'vocab.derafsh': Fixtures.vocab2,
            },
          ),
        ),
        srsRepositoryProvider.overrideWithValue(srs),
        gamificationRepositoryProvider.overrideWithValue(gamification),
        progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<ReviewState> loaded() async {
    container.listen(reviewControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container.read(reviewControllerProvider);
  }

  ReviewController controller() =>
      container.read(reviewControllerProvider.notifier);

  test('empty deck yields the empty phase', () async {
    final state = await loaded();
    expect(state.phase, ReviewPhase.empty);
  });

  test('due cards become questions with the correct option present', () async {
    final now = DateTime.now();
    await srs.ensureCards(['vocab.dadkhah', 'vocab.derafsh'], now);

    final state = await loaded();
    expect(state.phase, ReviewPhase.question);
    expect(state.queue, hasLength(2));

    final q = state.queue.first;
    expect(q.options, hasLength(2), reason: 'pool only has 2 items');
    expect(
      q.options[q.correctIndex],
      q.wordToMeaning ? q.vocab.meaning : q.vocab.word,
    );
  });

  test('a correct answer grades the card into the future', () async {
    await srs.ensureCards(['vocab.dadkhah'], DateTime.now());
    final state = await loaded();
    final q = state.current!;

    await controller().submit(q.correctIndex);

    final card = srs.cards['vocab.dadkhah']!;
    expect(card.reps, 1);
    expect(card.state, SrsState.review);
    expect(card.dueAt.isAfter(DateTime.now()), isTrue);
    expect(container.read(reviewControllerProvider).lastCorrect, isTrue);
  });

  test('a wrong answer lapses the card once and retries ungraded', () async {
    await srs.ensureCards(['vocab.dadkhah'], DateTime.now());
    final state = await loaded();
    final q = state.current!;
    final wrong = (q.correctIndex + 1) % q.options.length;

    await controller().submit(wrong);
    var s = container.read(reviewControllerProvider);
    expect(s.queue, hasLength(2), reason: 're-queued as retry');
    final repsAfterMiss = srs.cards['vocab.dadkhah']!.reps;

    await controller().next();
    await controller().submit(q.correctIndex); // retry, practice only
    expect(
      srs.cards['vocab.dadkhah']!.reps,
      repsAfterMiss,
      reason: 'retry must not re-grade FSRS state',
    );

    await controller().next();
    await Future<void>.delayed(Duration.zero);
    s = container.read(reviewControllerProvider);
    expect(s.phase, ReviewPhase.completed);
  });

  test('completion awards XP, refills hearts, unlocks first_review', () async {
    gamification.heartsState = HeartsState(
      count: 1,
      lastRefillAt: DateTime.now(),
    );
    await srs.ensureCards(['vocab.dadkhah'], DateTime.now());

    final state = await loaded();
    await controller().submit(state.current!.correctIndex);
    await controller().next();
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(reviewControllerProvider).phase,
      ReviewPhase.completed,
    );
    expect(
      gamification.xpEvents.single.amount,
      10,
      reason: 'all-correct bonus',
    );
    expect(gamification.heartsState.count, HeartsEconomy.max);
    expect(gamification.unlocked, contains('first_review'));
    expect(gamification.streakState.current, 1);
  });
}
