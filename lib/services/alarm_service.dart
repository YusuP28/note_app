import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static final AlarmService _i = AlarmService._();
  factory AlarmService() => _i;
  AlarmService._();

  static const _channel = MethodChannel('note_app/alarm');

  Future<bool> canScheduleExact() async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('canScheduleExact');
      return r ?? false;
    } catch (e) {
      debugPrint('canScheduleExact err: $e');
      return false;
    }
  }

  Future<bool> requestExactPermission() async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('requestExactPermission');
      return r ?? false;
    } catch (e) {
      debugPrint('requestExactPermission err: $e');
      return false;
    }
  }

  Future<bool> schedule({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('schedule', {
        'noteId': noteId,
        'title': title,
        'body': body,
        'whenMs': when.millisecondsSinceEpoch,
      });
      debugPrint('AlarmService.schedule → $r');
      return r ?? false;
    } catch (e) {
      debugPrint('schedule err: $e');
      return false;
    }
  }

  Future<bool> cancel(String noteId) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('cancel', {'noteId': noteId});
      return r ?? false;
    } catch (e) {
      debugPrint('cancel err: $e');
      return false;
    }
  }

  Future<bool> testNow({String? title, String? body}) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('testNow', {
        'noteId': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'title': title ?? 'Test Notifikasi',
        'body': body ?? 'Kalau ini muncul, notif berfungsi!',
      });
      return r ?? false;
    } catch (e) {
      debugPrint('testNow err: $e');
      return false;
    }
  }
}
