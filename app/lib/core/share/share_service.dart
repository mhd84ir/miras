import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hands text to the platform share sheet ("miras/share" channel). Sharing is
/// always user-initiated — nothing leaves the device on its own (PRD §6).
// One method today, but the interface/noop split is the house test seam for
// platform services (see NotificationService, HapticsService).
// ignore: one_member_abstracts
abstract interface class ShareService {
  Future<void> shareText(String text, {String? subject});
}

class IntentShareService implements ShareService {
  const IntentShareService();

  static const _channel = MethodChannel('miras/share');

  @override
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await _channel.invokeMethod('shareText', {
        'text': text,
        'subject': subject,
      });
    } on PlatformException {
      // Sharing is best-effort by nature; never surface a failure here.
    }
  }
}

/// Records shares for tests.
class NoopShareService implements ShareService {
  NoopShareService();

  final shared = <String>[];

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      shared.add(text);
}

/// Real instance provided at bootstrap; tests override with the no-op.
final shareServiceProvider = Provider<ShareService>(
  (ref) => throw UnimplementedError(
    'shareServiceProvider must be overridden at app bootstrap',
  ),
);
