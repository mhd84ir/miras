import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/notifications/notification_service.dart';
import 'package:miras/core/notifications/recap_body.dart';
import 'package:miras/features/gamification/data/gamification_repository.dart';
import 'package:miras/features/gamification/domain/streak_engine.dart';
import 'package:miras/features/review/data/srs_repository.dart';

/// Schedules (or refreshes) the daily recap with live streak and due-review
/// counts — called when the user opts in, and again whenever the app is
/// hidden so tonight's reminder reflects the day's actual state. If the app
/// stays closed, the last-known counts stand until the next open.
Future<bool> scheduleDailyRecap({
  required GamificationRepository gamification,
  required SrsRepository srs,
  required NotificationService notifications,
  required AppLocalizations strings,
  DateTime Function() now = DateTime.now,
}) async {
  final at = now();
  final streak = StreakEngine.effectiveCurrent(
    await gamification.streak(),
    at,
  );
  final due = await srs.watchDueCount(at).first;
  return notifications.enableDaily(
    title: strings.notificationTitle,
    body: recapBody(strings, streak: streak, due: due),
  );
}
