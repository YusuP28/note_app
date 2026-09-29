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

  static const _channelId = 'note_app_reminders';
  static const _channelName = 'Pengingat Catatan';
  static const _channelDesc = 'Notifikasi pengingat untuk catatan';

  Future<void> init() async {
    if (kIsWeb) return;
    if (_inited) return;
    _inited = true;

    tzdata.initializeTimeZones();

    // Set local timezone: coba Asia/Jakarta sebagai default Indonesia
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      debugPrint('TZ set: Asia/Jakarta');
    } catch (e) {
      debugPrint('TZ set failed: $e, fallback UTC');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
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
    final notifOk = await android?.requestNotificationsPermission();
    final exactOk = await android?.requestExactAlarmsPermission();
    debugPrint('Permission notif=$notifOk exact=$exactOk');
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
        ),
      );

  Future<void> schedule({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return;
    if (when.isBefore(DateTime.now())) {
      debugPrint('Skip schedule: waktu sudah lewat');
      return;
    }

    final id = _idFromString(noteId);
    final whenTz = tz.TZDateTime.from(when, tz.local);

    debugPrint('Schedule: id=$id when=$when whenTz=$whenTz tzLocal=${tz.local}');

    // Coba exact dulu
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
      debugPrint('✓ Scheduled EXACT id=$id');
      return;
    } catch (e) {
      debugPrint('Exact schedule FAILED: $e');
    }

    // Fallback 1: inexact
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
      debugPrint('✓ Scheduled INEXACT id=$id');
      return;
    } catch (e) {
      debugPrint('Inexact FAILED: $e');
    }

    // Fallback 2: show immediate (untuk debug)
    debugPrint('!!! Semua schedule gagal, coba show immediate');
    try {
      await _plugin.show(id, 'DEBUG: $title', body, _details);
    } catch (e) {
      debugPrint('Show immediate FAILED: $e');
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
