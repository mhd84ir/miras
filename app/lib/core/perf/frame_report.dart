/// Frame-performance statistics and the M8 budgets (docs/ROADMAP.md M8),
/// computed from raw samples so the math is unit-testable without a device.
library;

/// One rendered frame, extracted from `FrameTiming` by the perf harness.
/// `workUs` is buildDuration + rasterDuration — the workload the app
/// controls, which is what the 16.7 ms budget is written against.
/// `vsyncStartUs` is trace-clock micros (comparable to `Timeline.now`).
typedef FrameSample = ({int workUs, int vsyncStartUs});

/// A moment the UI was asked to transition (e.g. exercise → exercise);
/// frames within [FramePerfReport.transitionWindowUs] after it are
/// attributed to the transition.
typedef TransitionMark = ({String label, int atUs});

class TransitionStats {
  const TransitionStats({
    required this.label,
    required this.frames,
    required this.dropped,
  });

  final String label;
  final int frames;

  /// Frames over the per-frame budget inside this transition's window.
  final int dropped;
}

class FramePerfReport {
  const FramePerfReport({
    required this.totalFrames,
    required this.framesOverBudget,
    required this.framesSevere,
    required this.p50Us,
    required this.p90Us,
    required this.p99Us,
    required this.worstUs,
    required this.transitions,
  });

  factory FramePerfReport.compute(
    List<FrameSample> samples, {
    List<TransitionMark> transitions = const [],
  }) {
    final sorted = [...samples.map((s) => s.workUs)]..sort();
    // Nearest-rank: the smallest value ≥ p of the distribution.
    int percentile(double p) => sorted.isEmpty
        ? 0
        : sorted[((sorted.length * p).ceil() - 1).clamp(0, sorted.length - 1)];

    return FramePerfReport(
      totalFrames: samples.length,
      framesOverBudget: samples.where((s) => s.workUs > budgetFrameUs).length,
      framesSevere: samples.where((s) => s.workUs > budgetSevereUs).length,
      p50Us: percentile(0.50),
      p90Us: percentile(0.90),
      p99Us: percentile(0.99),
      worstUs: sorted.isEmpty ? 0 : sorted.last,
      transitions: [
        for (final mark in transitions)
          () {
            final inWindow = samples.where(
              (s) =>
                  s.vsyncStartUs >= mark.atUs &&
                  s.vsyncStartUs < mark.atUs + transitionWindowUs,
            );
            return TransitionStats(
              label: mark.label,
              frames: inWindow.length,
              dropped: inWindow.where((s) => s.workUs > budgetFrameUs).length,
            );
          }(),
      ],
    );
  }

  /// 60 Hz per-frame budget (build + raster).
  static const budgetFrameUs = 16700;

  /// "Zero frames > 100 ms post-launch".
  static const budgetSevereUs = 100000;

  /// "≥ 99% of frames within the frame budget".
  static const budgetSmoothRatio = 0.99;

  /// "≤ 1 dropped frame per lesson transition".
  static const budgetTransitionDropped = 1;

  /// How long after a transition mark a frame still counts as part of it.
  static const transitionWindowUs = 400000;

  final int totalFrames;
  final int framesOverBudget;
  final int framesSevere;
  final int p50Us;
  final int p90Us;
  final int p99Us;
  final int worstUs;
  final List<TransitionStats> transitions;

  double get smoothRatio =>
      totalFrames == 0 ? 1 : (totalFrames - framesOverBudget) / totalFrames;

  bool get smoothBudgetMet => smoothRatio >= budgetSmoothRatio;
  bool get severeBudgetMet => framesSevere == 0;
  bool get transitionBudgetMet =>
      transitions.every((t) => t.dropped <= budgetTransitionDropped);
  bool get allBudgetsMet =>
      smoothBudgetMet && severeBudgetMet && transitionBudgetMet;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'budgets': {
      'frame_us': budgetFrameUs,
      'severe_us': budgetSevereUs,
      'smooth_ratio': budgetSmoothRatio,
      'transition_dropped': budgetTransitionDropped,
    },
    'total_frames': totalFrames,
    'frames_over_budget': framesOverBudget,
    'frames_severe': framesSevere,
    'smooth_ratio': double.parse(smoothRatio.toStringAsFixed(4)),
    'p50_us': p50Us,
    'p90_us': p90Us,
    'p99_us': p99Us,
    'worst_us': worstUs,
    'transitions': [
      for (final t in transitions)
        {'label': t.label, 'frames': t.frames, 'dropped': t.dropped},
    ],
    'budgets_met': {
      'smooth': smoothBudgetMet,
      'severe': severeBudgetMet,
      'transitions': transitionBudgetMet,
      'all': allBudgetsMet,
    },
  };
}
