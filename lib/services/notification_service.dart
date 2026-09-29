import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _channelId = 'note_app_reminders_v3';
  static const _channelName = 'Pengingat Catatan';
  static const _channelDesc = 'Notifikasi pengingat untuk catatan';

  Future<void> init() async {
    if (kIsWeb) return;
    if (_inited) return;
    _inited = true;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      try { tz.setLocalLocation(tz.getLocation('UTC')); } catch (_) {}
    }

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
    try {
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      debugPrint('Permissions requested');
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          enableLights: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          fullScreenIntent: false,
          ticker: 'Pengingat Catatan',
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  Future<void> schedule({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return;

    final id = _idFromString(noteId);
    final now = DateTime.now();
    final whenTz = tz.TZDateTime.from(when, tz.local);

    debugPrint('=== SCHEDULE ===');
    debugPrint('noteId=$noteId');
    debugPrint('when=$when (local)');
    debugPrint('now=$now');
    debugPrint('diff=${when.difference(now).inSeconds}s');
    debugPrint('whenTz=$whenTz');

    if (when.isBefore(now.add(const Duration(seconds: 3)))) {
      debugPrint('SKIP: waktu terlalu dekat / lewat');
      return;
    }

    // Coba EXACT dulu
    try {
      await _plugin.zonedSchedule(
        id,
        title.isEmpty ? 'Pengingat Catatan' : title,
        body,
        whenTz,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
      debugPrint('✓ EXACT scheduled id=$id');
      return;
    } catch (e) {
      debugPrint('✗ EXACT failed: $e');
    }

    // Fallback INEXACT
    try {
      await _plugin.zonedSchedule(
        id,
        title.isEmpty ? 'Pengingat Catatan' : title,
        body,
        whenTz,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
      debugPrint('✓ INEXACT scheduled id=$id');
      return;
    } catch (e) {
      debugPrint('✗ INEXACT failed: $e');
    }

    // Fallback ALARM CLOCK (paling permisif)
    try {
      await _plugin.zonedSchedule(
        id,
        title.isEmpty ? 'Pengingat Catatan' : title,
        body,
        whenTz,
        _details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
      debugPrint('✓ ALARMCLOCK scheduled id=$id');
      return;
    } catch (e) {
      debugPrint('✗ ALARMCLOCK failed: $e');
    }

    // Fallback: tampilkan SEKARANG (debug)
    debugPrint('!!! Semua gagal, tampil immediate');
    try {
      await _plugin.show(id, title, body, _details);
    } catch (_) {}
  }

  Future<void> cancel(String noteId) async {
    if (kIsWeb) return;
    try { await _plugin.cancel(_idFromString(noteId)); } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try { await _plugin.cancelAll(); } catch (_) {}
  }

  Future<List<PendingNotificationRequest>> pending() async {
    if (kIsWeb) return [];
    return await _plugin.pendingNotificationRequests();
  }

  int _idFromString(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }
}
