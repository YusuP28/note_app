import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/initialize.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    final prefs = await SharedPreferences.getInstance();
    String soundPref = prefs.getString('notification_sound') ?? 'sound1';

    AndroidNotificationSound? androidSound;
    if (['sound1', 'sound2', 'sound3'].contains(soundPref)) {
      androidSound = RawResourceAndroidNotificationSound(soundPref);
    } else if (soundPref.isNotEmpty) {
      androidSound = UriAndroidNotificationSound(soundPref);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'note_app_alarm_v2',
      'Note Alarm & Reminders',
      description: 'Channel for note alarms and reminders',
      importance: Importance.max,
      sound: androidSound,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
