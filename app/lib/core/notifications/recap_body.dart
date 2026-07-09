import 'package:miras/core/l10n/gen/app_localizations.dart';
import 'package:miras/core/persian_text/persian_text.dart';

/// Composes the daily-recap notification body from live counts (PRD §5.3:
/// "streak status and due reviews"), falling back to the generic reminder
/// when there is nothing concrete to say.
String recapBody(
  AppLocalizations strings, {
  required int streak,
  required int due,
}) {
  final s = PersianText.number(streak);
  final d = PersianText.number(due);
  return switch ((streak > 0, due > 0)) {
    (true, true) => strings.notificationBodyStreakDue(s, d),
    (true, false) => strings.notificationBodyStreak(s),
    (false, true) => strings.notificationBodyDue(d),
    (false, false) => strings.notificationBody,
  };
}
