import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _channelId = 'note_app_reminders';
  static const _channelName = 'Pengingat Catatan';
  static const _channelDesc = 'Notifikasi pengingat untuk catatan';

  Future<void> init() async {
    if (kIsWeb) return; // skip di web
    if (_inited) return;
    _inited = true;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('Notif tapped: ${resp.payload}');
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

  Future<void> schedule({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return;
    if (when.isBefore(DateTime.now())) return;

    final id = _idFromString(noteId);
    final whenTz = tz.TZDateTime.from(when, tz.local);

    try {
      await _plugin.zonedSchedule(
        id,
        title.isEmpty ? 'Pengingat' : title,
        body,
        whenTz,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
      debugPrint('Scheduled notif id=$id at $when');
    } catch (e) {
      debugPrint('Schedule ERROR: $e');
      try {
        await _plugin.zonedSchedule(
          id,
          title.isEmpty ? 'Pengingat' : title,
          body,
          whenTz,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: noteId,
        );
      } catch (e2) {
        debugPrint('Schedule fallback ERROR: $e2');
      }
    }
  }

  Future<void> cancel(String noteId) async {
    if (kIsWeb) return;
    await _plugin.cancel(_idFromString(noteId));
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  int _idFromString(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }
}
