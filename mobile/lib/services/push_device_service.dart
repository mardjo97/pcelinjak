import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'device_id_service.dart';
import 'notification_nav.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// FCM token → pčelinjak backend → notification-service.
class PushDeviceService {
  PushDeviceService(this.api);

  final ApiClient api;

  static const _tokenPrefsKey = 'fcm_token';
  static const _lastRegisteredKey = 'fcm_token_registered';
  static bool _firebaseReady = false;
  static bool _listenersBound = false;

  static Future<void> initFirebase() async {
    if (_firebaseReady) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  Future<void> start() async {
    await initFirebase();
    if (!_firebaseReady) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_listenersBound) {
      _listenersBound = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        onNewFcmToken(token);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _openFromMessage(initial);
      }
    }

    await syncWithBackend(force: true);
  }

  static void _openFromMessage(RemoteMessage message) {
    final data = message.data;
    final uuid = data['reminderUuid'] as String?;
    if (uuid != null && uuid.isNotEmpty) {
      NotificationNav.openReminder(uuid);
      return;
    }
    if (data['type'] == 'reminder' && data['hiveUuid'] != null) {
      // fallback: barem reminderUuid bi trebalo da postoji
      NotificationNav.openReminder(data['reminderUuid'] as String?);
    }
  }

  Future<void> syncWithBackend({bool force = false}) async {
    if (!await api.isLoggedIn()) return;

    try {
      final me = await api.get('/me') as Map<String, dynamic>;
      final needsRefresh = me['needsFcmRefresh'] == true;
      final token = await _resolveToken();
      if (token == null || token.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_lastRegisteredKey);
      if (!force && !needsRefresh && last == token) {
        return;
      }

      final deviceId = await DeviceIdService.getOrCreate();
      await api.put('/me/device', {
        'deviceId': deviceId,
        'fcmToken': token,
      });
      await prefs.setString(_tokenPrefsKey, token);
      await prefs.setString(_lastRegisteredKey, token);
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  Future<void> onNewFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
    await syncWithBackend(force: true);
  }

  Future<String?> _resolveToken() async {
    if (_firebaseReady) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        debugPrint('FCM getToken failed: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tokenPrefsKey);
    if (stored != null && stored.trim().isNotEmpty && !stored.startsWith('pending-fcm-')) {
      return stored.trim();
    }
    return null;
  }
}
