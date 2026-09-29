package com.yusup28.note_app

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "note_app/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val noteId = call.argument<String>("noteId") ?: ""
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val whenMs = call.argument<Long>("whenMs") ?: 0L
                        if (noteId.isEmpty() || whenMs <= 0L) {
                            result.error("ARG", "Missing args", null)
                            return@setMethodCallHandler
                        }
                        AlarmScheduler.schedule(this, noteId, title, body, whenMs)
                        result.success(true)
                    }
                    "cancel" -> {
                        val noteId = call.argument<String>("noteId") ?: ""
                        AlarmScheduler.cancel(this, noteId)
                        result.success(true)
                    }
                    "canScheduleExact" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                            result.success(true)
                        } else {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            result.success(am.canScheduleExactAlarms())
                        }
                    }
                    "requestExactPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = Uri.parse("package:$packageName")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("ERR", e.message, null)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "openChannelSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                putExtra(Settings.EXTRA_CHANNEL_ID,
                                    call.argument<String>("channelId") ?: "note_app_alarm_v3_sound1")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR", e.message, null)
                        }
                    }
                    "testNow" -> {
                        val noteId = call.argument<String>("noteId") ?: "test"
                        val title = call.argument<String>("title") ?: "Test Notifikasi"
                        val body = call.argument<String>("body") ?: "Kalau ini muncul, notif berfungsi!"
                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            putExtra("noteId", noteId)
                            putExtra("title", title)
                            putExtra("body", body)
                        }
                        sendBroadcast(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
