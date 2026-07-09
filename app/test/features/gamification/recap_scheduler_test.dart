import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/notifications/notification_service.dart';
import 'package:miras/core/notifications/recap_body.dart';
import 'package:miras/features/gamification/application/recap_scheduler.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';

import '../../helpers/fakes.dart';

class _RecordingNotifications implements NotificationService {
  String? title;
  String? body;
  int enableCalls = 0;

  @override
  Future<bool> enableDaily({
    required String title,
    required String body,
  }) async {
    enableCalls++;
    this.title = title;
    this.body = body;
    return true;
  }

  @override
  Future<void> disableDaily() async {}
}

void main() {
  final strings = lookupAppLocalizations(const Locale('fa'));
  final now = DateTime(2026, 7, 9, 12);

  test('schedules with live streak and due counts', () async {
    final gamification = FakeGamificationRepository(now: now)
      ..streakState = StreakState(
        current: 4,
        longest: 9,
        lastActiveDate: DateTime(2026, 7, 9),
      );
    final srs = FakeSrsRepository();
    await srs.ensureCards(['vocab.a', 'vocab.b'], now);
    final notifications = _RecordingNotifications();

    final granted = await scheduleDailyRecap(
      gamification: gamification,
      srs: srs,
      notifications: notifications,
      strings: strings,
      now: () => now,
    );

    expect(granted, isTrue);
    expect(notifications.enableCalls, 1);
    expect(notifications.title, strings.notificationTitle);
    expect(notifications.body, recapBody(strings, streak: 4, due: 2));
  });

  test('a lapsed streak schedules the due-only body', () async {
    final gamification = FakeGamificationRepository(now: now)
      ..streakState = StreakState(
        current: 4,
        longest: 9,
        // Two days silent — the effective streak the user sees is 0.
        lastActiveDate: DateTime(2026, 7, 7),
      );
    final srs = FakeSrsRepository();
    await srs.ensureCards(['vocab.a'], now);
    final notifications = _RecordingNotifications();

    await scheduleDailyRecap(
      gamification: gamification,
      srs: srs,
      notifications: notifications,
      strings: strings,
      now: () => now,
    );

    expect(notifications.body, recapBody(strings, streak: 0, due: 1));
  });
}
