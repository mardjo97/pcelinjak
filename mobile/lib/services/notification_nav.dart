import 'package:flutter/material.dart';

import '../screens/reminder_detail_screen.dart';

/// Globalna navigacija iz notifikacija (lokalnih i FCM).
class NotificationNav {
  NotificationNav._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static String? _pendingReminderUuid;

  static void openReminder(String? reminderUuid) {
    if (reminderUuid == null || reminderUuid.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingReminderUuid = reminderUuid;
      return;
    }
    nav.push(
      MaterialPageRoute(builder: (_) => ReminderDetailScreen(reminderUuid: reminderUuid)),
    );
  }

  /// Pozovi kad je navigator spreman (npr. posle prvog frame-a na Home).
  static void flushPending() {
    final uuid = _pendingReminderUuid;
    if (uuid == null) return;
    _pendingReminderUuid = null;
    openReminder(uuid);
  }
}
