import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miras/core/content/content_providers.dart';
import 'package:miras/core/content/exercise_prompt.dart';
import 'package:miras/features/gamification/application/gamification_service.dart';
import 'package:miras/features/home_path/data/progress_repository.dart';
import 'package:miras/features/lesson/application/lesson_loader.dart';
import 'package:miras/features/lesson/domain/exercise_answer.dart';
import 'package:miras/features/lesson/domain/lesson_result.dart';
import 'package:miras/features/lesson/domain/loaded_exercise.dart';

enum LessonPhase {
  /// Exercises are being loaded from the pack.
  loading,

  /// An exercise is on screen awaiting an answer.
  question,

  /// The answer was checked; feedback banner is showing.
  feedback,

  /// The lesson ended — successfully or out of hearts.
  completed,
}

@immutable
class LessonState {
  const LessonState({
    required this.phase,
    this.queue = const [],
    this.index = 0,
    this.hearts = 0,
    this.lastCorrect,
    this.firstTryCorrectIds = const {},
    this.answeredIds = const {},
    this.result,
    this.failed = false,
    this.outOfHearts = false,
  });

  final LessonPhase phase;

  /// Exercises to run, in order. Wrong answers re-queue a copy at the end,
  /// so the queue can be longer than the lesson's exercise list.
  final List<LoadedExercise> queue;
  final int index;
  final int hearts;

  /// Outcome of the most recent answer (drives the feedback banner).
  final bool? lastCorrect;

  /// Exercise ids answered correctly on their FIRST attempt.
  final Set<String> firstTryCorrectIds;

  /// Exercise ids attempted at least once.
  final Set<String> answeredIds;

  /// Set when [phase] is completed and the lesson succeeded.
  final LessonResult? result;

  /// True when hearts ran out before the queue finished.
  final bool failed;

  /// True when the lesson could not even start (or failed) because the
  /// persistent heart supply is empty — the UI points to review practice.
  final bool outOfHearts;

  LoadedExercise? get current =>
      phase == LessonPhase.question || phase == LessonPhase.feedback
      ? queue[index]
      : null;

  /// Progress through the queue, for the top progress bar. The queue grows
  /// when answers are wrong, so the bar can advance more slowly — same
  /// behavior users know from Duolingo.
  double get progress => queue.isEmpty ? 0 : (index / queue.length).clamp(0, 1);

  LessonState copyWith({
    LessonPhase? phase,
    List<LoadedExercise>? queue,
    int? index,
    int? hearts,
    bool? lastCorrect,
    Set<String>? firstTryCorrectIds,
    Set<String>? answeredIds,
    LessonResult? result,
    bool? failed,
    bool? outOfHearts,
  }) {
    return LessonState(
      phase: phase ?? this.phase,
      queue: queue ?? this.queue,
      index: index ?? this.index,
      hearts: hearts ?? this.hearts,
      lastCorrect: lastCorrect,
      firstTryCorrectIds: firstTryCorrectIds ?? this.firstTryCorrectIds,
      answeredIds: answeredIds ?? this.answeredIds,
      result: result ?? this.result,
      failed: failed ?? this.failed,
      outOfHearts: outOfHearts ?? this.outOfHearts,
    );
  }
}

// ignore: specify_nonobvious_property_types — riverpod family type is verbose
final lessonControllerProvider = NotifierProvider.autoDispose
    .family<LessonController, LessonState, String>(LessonController.new);

class LessonController extends Notifier<LessonState> {
  LessonController(this.lessonId);

  final String lessonId;

  late final String _sessionId =
      '$lessonId-${DateTime.now().millisecondsSinceEpoch}';

  @override
  LessonState build() {
    unawaited(Future.microtask(_load));
    return const LessonState(phase: LessonPhase.loading);
  }

  Future<void> _load() async {
    final hearts = await ref.read(gamificationServiceProvider).settledHearts();
    if (!ref.mounted) return;

    if (hearts.count <= 0) {
      state = state.copyWith(
        phase: LessonPhase.completed,
        failed: true,
        outOfHearts: true,
      );
      return;
    }

    final loader = LessonLoader(ref.read(contentRepositoryProvider));
    final exercises = await loader.load(lessonId);
    if (!ref.mounted) return;
    state = LessonState(
      phase: LessonPhase.question,
      queue: exercises,
      hearts: hearts.count,
    );
  }

  /// Submits the answer for the current exercise.
  ///
  /// Presentation exercises advance immediately; interactive ones move to
  /// the feedback phase, cost a heart when wrong, and re-queue at the end.
  Future<void> submit(ExerciseAnswer answer) async {
    final current = state.current;
    if (state.phase != LessonPhase.question || current == null) return;

    if (current.prompt.isPresentation) {
      _advance();
      return;
    }

    final correct = current.check(answer);
    final id = current.exercise.id;
    final firstAttempt = !state.answeredIds.contains(id);

    await ref
        .read(progressRepositoryProvider)
        .logAttempt(
          exerciseId: id,
          wasCorrect: correct,
          lessonSessionId: _sessionId,
        );

    // Wrong answers cost a persistent heart (docs/DATA_MODEL.md §4).
    var hearts = state.hearts;
    if (!correct) {
      hearts = (await ref.read(gamificationServiceProvider).spendHeart()).count;
      if (!ref.mounted) return;
    }

    state = state.copyWith(
      phase: LessonPhase.feedback,
      lastCorrect: correct,
      hearts: hearts,
      answeredIds: {...state.answeredIds, id},
      firstTryCorrectIds: correct && firstAttempt
          ? {...state.firstTryCorrectIds, id}
          : state.firstTryCorrectIds,
      // Wrong answers come back at the end of the queue until solved.
      queue: correct ? state.queue : [...state.queue, current],
    );
  }

  /// Dismisses the feedback banner and moves on.
  Future<void> next() async {
    if (state.phase != LessonPhase.feedback) return;

    if (state.hearts <= 0) {
      state = state.copyWith(
        phase: LessonPhase.completed,
        failed: true,
        outOfHearts: true,
      );
      return;
    }
    _advance();
  }

  void _advance() {
    final nextIndex = state.index + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(phase: LessonPhase.question, index: nextIndex);
      return;
    }
    unawaited(_complete());
  }

  Future<void> _complete() async {
    final interactive = {
      for (final e in state.queue)
        if (!e.prompt.isPresentation) e.exercise.id,
    };
    final result = LessonResult(
      lessonId: lessonId,
      interactiveCount: interactive.length,
      correctFirstTry: state.firstTryCorrectIds.length,
    );
    await ref.read(progressRepositoryProvider).recordCompletion(result);

    // Vocabulary formally introduced in this lesson enters the SRS deck.
    final introducedVocabIds = {
      for (final e in state.queue)
        if (e.prompt case VocabIntroPrompt(:final vocabId)) vocabId,
    }.toList();
    await ref
        .read(gamificationServiceProvider)
        .onLessonCompleted(
          result,
          introducedVocabIds: introducedVocabIds,
        );

    if (!ref.mounted) return;
    state = state.copyWith(phase: LessonPhase.completed, result: result);
  }
}
