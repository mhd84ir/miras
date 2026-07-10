import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Physical feedback (DESIGN_SYSTEM.md §5): a gentle tick for correct, a firm
/// buzz for wrong, a double pulse for completion. Talks to the device
/// vibrator directly via the `miras/haptics` channel — the framework's
/// HapticFeedback.*Impact variants are view-level effects gated behind the
/// system "touch feedback" setting, which is off (or OEM-ignored) on many
/// devices and made answers feel dead in the beta device pass.
abstract interface class HapticsService {
  /// Correct answer: short, light.
  Future<void> success();

  /// Wrong answer: longer, unmistakable.
  Future<void> failure();

  /// Lesson completed: a small two-pulse celebration.
  Future<void> celebrate();
}

class VibratorHapticsService implements HapticsService {
  /// [enabled] is the live haptics setting (`watchProfile().map(...)` at
  /// bootstrap); the service caches the latest value so answering costs no
  /// database read.
  VibratorHapticsService({required Stream<bool> enabled}) {
    enabled.listen((value) => _enabled = value);
  }

  static const _channel = MethodChannel('miras/haptics');

  var _enabled = true;

  Future<void> _vibrate({
    required int durationMs,
    required int amplitude,
  }) async {
    if (!_enabled) return;
    try {
      await _channel.invokeMethod<void>('vibrate', {
        'durationMs': durationMs,
        'amplitude': amplitude,
      });
    } on PlatformException {
      // No vibrator — feedback is optional, never an error in the flow.
    } on MissingPluginException {
      // Non-Android host (tests, future iOS until the channel exists there).
    }
  }

  @override
  Future<void> success() => _vibrate(durationMs: 25, amplitude: 120);

  @override
  Future<void> failure() => _vibrate(durationMs: 90, amplitude: 255);

  @override
  Future<void> celebrate() async {
    await _vibrate(durationMs: 30, amplitude: 140);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await _vibrate(durationMs: 60, amplitude: 220);
  }
}

/// Records calls for tests.
class NoopHapticsService implements HapticsService {
  NoopHapticsService();

  int successCount = 0;
  int failureCount = 0;
  int celebrateCount = 0;

  @override
  Future<void> success() async => successCount++;

  @override
  Future<void> failure() async => failureCount++;

  @override
  Future<void> celebrate() async => celebrateCount++;
}

/// Real instance provided at bootstrap; tests override with the no-op.
final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => throw UnimplementedError(
    'hapticsServiceProvider must be overridden at app bootstrap',
  ),
);
