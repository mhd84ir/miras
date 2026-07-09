import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/perf/frame_report.dart';

FrameSample frame(int workUs, {int at = 0}) => (
  workUs: workUs,
  vsyncStartUs: at,
);

void main() {
  test('an empty session trivially meets every budget', () {
    final r = FramePerfReport.compute(const []);
    expect(r.totalFrames, 0);
    expect(r.smoothRatio, 1);
    expect(r.allBudgetsMet, isTrue);
    expect(r.p99Us, 0);
  });

  test('percentiles and worst frame come from sorted work durations', () {
    final r = FramePerfReport.compute([
      for (var i = 1; i <= 100; i++) frame(i * 1000),
    ]);
    expect(r.p50Us, 50000);
    expect(r.p90Us, 90000);
    expect(r.p99Us, 99000);
    expect(r.worstUs, 100000);
  });

  test('smooth budget: 99% within 16.7 ms', () {
    // 99 fast frames + 1 janky one out of 100 → exactly 0.99, budget met.
    final met = FramePerfReport.compute([
      for (var i = 0; i < 99; i++) frame(8000),
      frame(20000),
    ]);
    expect(met.smoothRatio, 0.99);
    expect(met.smoothBudgetMet, isTrue);

    // 2 janky out of 100 → 0.98, budget missed.
    final missed = FramePerfReport.compute([
      for (var i = 0; i < 98; i++) frame(8000),
      frame(20000),
      frame(20000),
    ]);
    expect(missed.smoothBudgetMet, isFalse);
  });

  test('a single >100 ms frame fails the severe budget', () {
    final r = FramePerfReport.compute([frame(8000), frame(100001)]);
    expect(r.framesSevere, 1);
    expect(r.severeBudgetMet, isFalse);
    expect(r.allBudgetsMet, isFalse);
  });

  test('transition windows attribute only frames inside 400 ms', () {
    final r = FramePerfReport.compute(
      [
        frame(20000, at: 1000000), // inside window: dropped
        frame(8000, at: 1200000), // inside window: fine
        frame(20000, at: 1400001), // outside window
      ],
      transitions: [(label: 't1', atUs: 1000000)],
    );
    final t = r.transitions.single;
    expect(t.frames, 2);
    expect(t.dropped, 1);
    expect(r.transitionBudgetMet, isTrue, reason: '1 dropped is the limit');
  });

  test('two dropped frames in one transition miss the budget', () {
    final r = FramePerfReport.compute(
      [frame(20000, at: 1000), frame(30000, at: 2000)],
      transitions: [(label: 't1', atUs: 0)],
    );
    expect(r.transitions.single.dropped, 2);
    expect(r.transitionBudgetMet, isFalse);
  });

  test('json is schema-versioned and carries budget verdicts', () {
    final json = FramePerfReport.compute([frame(8000)]).toJson();
    expect(json['schema'], 1);
    expect(json['total_frames'], 1);
    final verdicts = json['budgets_met']! as Map<String, Object?>;
    expect(verdicts['all'], true);
  });
}
