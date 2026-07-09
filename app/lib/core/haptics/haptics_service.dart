import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Physical answer feedback (DESIGN_SYSTEM.md §5): a gentle tick for correct,
/// a firm buzz for wrong. Talks to the device vibrator directly via the
/// `miras/haptics` channel — the framework's HapticFeedback.*Impact variants
/// are view-level effects gated behind the system "touch feedback" setting,
/// which is off (or OEM-ignored) on many devices and made answers feel dead
/// in the beta device pass.
abstract interface class HapticsService {
  /// Correct answer: short, light.
  Future<void> success();

  /// Wrong answer: longer, unmistakable.
  Future<void> failure();
}

class VibratorHapticsService implements HapticsService {
  const VibratorHapticsService();

  static const _channel = MethodChannel('miras/haptics');

  Future<void> _vibrate({
    required int durationMs,
    required int amplitude,
  }) async {
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
}

/// Records calls for tests.
class NoopHapticsService implements HapticsService {
  NoopHapticsService();

  int successCount = 0;
  int failureCount = 0;

  @override
  Future<void> success() async => successCount++;

  @override
  Future<void> failure() async => failureCount++;
}

/// Real instance provided at bootstrap; tests override with the no-op.
final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => throw UnimplementedError(
    'hapticsServiceProvider must be overridden at app bootstrap',
  ),
);
