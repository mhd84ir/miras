import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/models.dart';
import 'package:miras/features/gamification/application/gamification_service.dart';
import 'package:miras/features/review/data/srs_repository.dart';
import 'package:miras/features/review/domain/fsrs_scheduler.dart';
import 'package:miras/features/review/domain/srs_card.dart';

/// Answering slower than this maps a correct answer to `hard` instead of
/// `good` (docs/DATA_MODEL.md §5).
const hardAnswerThreshold = Duration(seconds: 10);

/// One generated review question: recognize the meaning of a word, or the
/// word for a meaning.
@immutable
class ReviewQuestion {
  const ReviewQuestion({
    required this.card,
    required this.vocab,
    required this.wordToMeaning,
    required this.options,
    required this.correctIndex,
    this.isRetry = false,
  });

  final SrsCard card;
  final VocabItem vocab;

  /// true: show the word, choose the meaning; false: the reverse.
  final bool wordToMeaning;
  final List<String> options;
  final int correctIndex;

  /// A re-queued miss: practice only — the FSRS lapse was already recorded
  /// on the first attempt and must not be graded twice.
  final bool isRetry;

  String get prompt => wordToMeaning ? vocab.word : vocab.meaning;

  ReviewQuestion asRetry() => ReviewQuestion(
    card: card,
    vocab: vocab,
    wordToMeaning: wordToMeaning,
    options: options,
    correctIndex: correctIndex,
    isRetry: true,
  );
}

enum ReviewPhase { loading, empty, question, feedback, completed }

@immutable
class ReviewState {
  const ReviewState({
    required this.phase,
    this.queue = const [],
    this.index = 0,
    this.lastCorrect,
    this.hadWrongAnswer = false,
    this.reviewedCount = 0,
  });

  final ReviewPhase phase;
  final List<ReviewQuestion> queue;
  final int index;
  final bool? lastCorrect;

  /// Any wrong answer in the session forfeits the all-correct XP bonus.
  final bool hadWrongAnswer;

  /// Unique cards graded so far (drives the progress bar).
  final int reviewedCount;

  ReviewQuestion? get current =>
      phase == ReviewPhase.question || phase == ReviewPhase.feedback
      ? queue[index]
      : null;

  double get progress => queue.isEmpty ? 0 : (index / queue.length).clamp(0, 1);

  ReviewState copyWith({
    ReviewPhase? phase,
    List<ReviewQuestion>? queue,
    int? index,
    bool? lastCorrect,
    bool? hadWrongAnswer,
    int? reviewedCount,
  }) {
    return ReviewState(
      phase: phase ?? this.phase,
      queue: queue ?? this.queue,
      index: index ?? this.index,
      lastCorrect: lastCorrect,
      hadWrongAnswer: hadWrongAnswer ?? this.hadWrongAnswer,
      reviewedCount: reviewedCount ?? this.reviewedCount,
    );
  }
}

// ignore: specify_nonobvious_property_types — riverpod provider types are verbose
final reviewControllerProvider =
    NotifierProvider.autoDispose<ReviewController, ReviewState>(
      ReviewController.new,
    );

class ReviewController extends Notifier<ReviewState> {
  static const scheduler = FsrsScheduler();
  static const optionCount = 4;

  late final String _sessionId =
      'review-${DateTime.now().millisecondsSinceEpoch}';

  DateTime _questionShownAt = DateTime.now();

  @override
  ReviewState build() {
    unawaited(Future.microtask(_load));
    return const ReviewState(phase: ReviewPhase.loading);
  }

  Future<void> _load() async {
    final now = DateTime.now();
    // Session size uses the repository's default cap of 20 cards.
    final cards = await ref.read(srsRepositoryProvider).dueCards(now);
    if (!ref.mounted) return;

    if (cards.isEmpty) {
      state = const ReviewState(phase: ReviewPhase.empty);
      return;
    }

    final content = ref.read(contentRepositoryProvider);
    final vocabById = {
      for (final v in await content.vocabByIds(
        [for (final c in cards) c.vocabularyItemId],
      ))
        v.id: v,
    };
    final pool = await content.allVocab();
    if (!ref.mounted) return;

    final random = Random(now.millisecondsSinceEpoch);
    final questions = <ReviewQuestion>[
      for (final (i, card) in cards.indexed)
        if (vocabById[card.vocabularyItemId] != null)
          _generate(
            card,
            vocabById[card.vocabularyItemId]!,
            pool,
            random,
            wordToMeaning: i.isEven,
          ),
    ];

    _questionShownAt = DateTime.now();
    state = ReviewState(phase: ReviewPhase.question, queue: questions);
  }

  ReviewQuestion _generate(
    SrsCard card,
    VocabItem vocab,
    List<VocabItem> pool,
    Random random, {
    required bool wordToMeaning,
  }) {
    String textOf(VocabItem v) => wordToMeaning ? v.meaning : v.word;

    final distractors = pool.where((v) => v.id != vocab.id).toList()
      ..shuffle(random);
    final options = [
      textOf(vocab),
      for (final d in distractors.take(optionCount - 1)) textOf(d),
    ]..shuffle(random);

    return ReviewQuestion(
      card: card,
      vocab: vocab,
      wordToMeaning: wordToMeaning,
      options: options,
      correctIndex: options.indexOf(textOf(vocab)),
    );
  }

  Future<void> submit(int optionIndex) async {
    final current = state.current;
    if (state.phase != ReviewPhase.question || current == null) return;

    final now = DateTime.now();
    final correct = optionIndex == current.correctIndex;

    if (!current.isRetry) {
      final slow = now.difference(_questionShownAt) > hardAnswerThreshold;
      final grade = !correct
          ? SrsGrade.again
          : slow
          ? SrsGrade.hard
          : SrsGrade.good;
      final updated = scheduler.review(current.card, grade, now);
      await ref.read(srsRepositoryProvider).saveCard(updated);
      if (!ref.mounted) return;
    }

    state = state.copyWith(
      phase: ReviewPhase.feedback,
      lastCorrect: correct,
      hadWrongAnswer: state.hadWrongAnswer || !correct,
      reviewedCount: state.reviewedCount + 1,
      // Missed words come back once more at the end of the session,
      // as ungraded practice.
      queue: correct ? state.queue : [...state.queue, current.asRetry()],
    );
  }

  Future<void> next() async {
    if (state.phase != ReviewPhase.feedback) return;
    final nextIndex = state.index + 1;
    if (nextIndex < state.queue.length) {
      _questionShownAt = DateTime.now();
      state = state.copyWith(phase: ReviewPhase.question, index: nextIndex);
      return;
    }

    await ref
        .read(gamificationServiceProvider)
        .onReviewCompleted(
          allCorrect: !state.hadWrongAnswer,
          sessionId: _sessionId,
        );
    if (!ref.mounted) return;
    state = state.copyWith(phase: ReviewPhase.completed);
  }
}
