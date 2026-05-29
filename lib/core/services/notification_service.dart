import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:purenote/core/database/daos/note_dao.dart';
import 'package:purenote/core/routing/app_router.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'purenote_reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Note reminder notifications';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    rootNavigatorKey.currentState?.pushReplacementNamed('/note/$payload');
  }

  static Future<void> schedule(
    NoteDao dao,
    String noteId,
    String title,
    DateTime reminderAt,
  ) async {
    final now = DateTime.now();
    final delay = reminderAt.difference(now);
    if (delay.isNegative) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    await _plugin.show(
      noteId.hashCode,
      title.isNotEmpty ? title : 'Note reminder',
      'Tap to open your note',
      NotificationDetails(android: androidDetails),
      payload: noteId,
    );
  }

  static Future<void> cancel(String noteId) async {
    await _plugin.cancel(noteId.hashCode);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

