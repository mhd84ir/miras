import 'package:flutter/foundation.dart';

/// Hearts state (docs/DATA_MODEL.md §2). Refill is computed lazily on read —
/// no background jobs (invariant from the data model).
@immutable
class HeartsState {
  const HeartsState({required this.count, required this.lastRefillAt});

  final int count;

  /// Reference point for lazy refill computation. Meaningful only while
  /// count < max; parked at the last spend/refill otherwise.
  final DateTime lastRefillAt;
}

/// Pure hearts rules: max 5, −1 per wrong lesson answer, +1 per 4h,
/// full refill on completing a review session (docs/DATA_MODEL.md §4).
abstract final class HeartsEconomy {
  static const max = 5;
  static const refillEvery = Duration(hours: 4);

  static HeartsState full(DateTime now) =>
      HeartsState(count: max, lastRefillAt: now);

  /// Applies lazy time-based refill up to [now].
  static HeartsState settle(HeartsState s, DateTime now) {
    if (s.count >= max) return s;
    final elapsed = now.difference(s.lastRefillAt);
    if (elapsed.isNegative) return s;

    final earned = elapsed.inMinutes ~/ refillEvery.inMinutes;
    if (earned <= 0) return s;

    final count = (s.count + earned).clamp(0, max);
    return HeartsState(
      count: count,
      lastRefillAt: count >= max
          ? now
          : s.lastRefillAt.add(refillEvery * earned),
    );
  }

  /// Spends one heart (wrong answer in a lesson). Call [settle] first.
  static HeartsState spend(HeartsState s, DateTime now) {
    if (s.count <= 0) return s;
    return HeartsState(
      // Refill countdown starts from the moment a full set is broken.
      lastRefillAt: s.count == max ? now : s.lastRefillAt,
      count: s.count - 1,
    );
  }

  /// Completing a review session restores all hearts — practicing old
  /// material is the healthy way back into lessons (PRD §5.3).
  static HeartsState refillFull(DateTime now) => full(now);

  /// When the next heart arrives, or null if already full.
  static DateTime? nextRefillAt(HeartsState s) =>
      s.count >= max ? null : s.lastRefillAt.add(refillEvery);
}
