# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# timezone
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.bp.**
