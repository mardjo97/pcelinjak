import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_nav.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _ready = true;

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _handlePayload(launch!.notificationResponse?.payload);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    final uuid = reminderUuidFromPayload(payload);
    if (uuid != null) {
      NotificationNav.openReminder(uuid);
    }
  }

  static String? reminderUuidFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final uuid = map['reminderUuid'] as String?;
      if (uuid != null && uuid.isNotEmpty) return uuid;
    } catch (_) {
      // legacy: plain uuid string
      if (!payload.startsWith('{')) return payload;
    }
    return null;
  }

  static String payloadFor(String reminderUuid) =>
      jsonEncode({'type': 'reminder', 'reminderUuid': reminderUuid});

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? reminderUuid,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pcelinjak_reminders',
          'Podsetnici',
          channelDescription: 'Podsetnici za kontrolu i zamenu matica',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminderUuid != null ? payloadFor(reminderUuid) : null,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}
