import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Daily recap reminder (PRD §5.3): one local notification per day, opt-in.
abstract interface class NotificationService {
  /// Requests permission (Android 13+) and schedules the daily reminder.
  /// Returns false when the user denied notification permission.
  Future<bool> enableDaily({required String title, required String body});

  Future<void> disableDaily();
}

/// Plugin-backed implementation. Scheduling is inexact — a reminder does
/// not need the exact-alarm permission.
class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _dailyId = 1;
  static const _reminderHour = 20;

  var _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception {
      // Fall back to the package default (UTC) rather than failing —
      // an off-by-timezone reminder beats a crash.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> enableDaily({
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return false;

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _reminderHour,
    );
    if (when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_recap',
          'یادآور روزانه',
          channelDescription: 'یادآوری روزانهٔ مرور و پیوستگی',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  @override
  Future<void> disableDaily() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _dailyId);
  }
}

/// No-op for tests.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<bool> enableDaily({
    required String title,
    required String body,
  }) async => true;

  @override
  Future<void> disableDaily() async {}
}

/// Real instance provided at bootstrap; tests override with the no-op.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(
    'notificationServiceProvider must be overridden at app bootstrap',
  ),
);
