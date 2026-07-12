import 'package:flutter_test/flutter_test.dart';
import 'package:miras/core/crash/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('crash config never sends PII, screenshots, or traces (ADR-0007)', () {
    final options = SentryFlutterOptions()..dsn = 'ignored';
    configureSentryOptions(options);

    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    expect(options.tracesSampleRate, isNull);
    expect(options.environment, 'dev', reason: 'tests run in debug mode');
  });

  test('a build without --dart-define ships with reporting disabled', () {
    expect(sentryDsn, isEmpty);
  });

  test('beforeSend strips the install id and IP from every event', () async {
    final options = SentryFlutterOptions()..dsn = 'ignored';
    configureSentryOptions(options);

    final event = SentryEvent(
      user: SentryUser(
        id: '98860d5e166649e1b00147de6dea708f',
        ipAddress: '5.212.6.0',
      ),
    );
    final sent = (await options.beforeSend!(event, Hint()))!;

    expect(sent.user?.id, isNull);
    expect(sent.user?.ipAddress, isNull);
  });
}
