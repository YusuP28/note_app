package com.yusup28.note_app

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmActivity : FlutterActivity() {
    private val CHANNEL = "note_app/alarm_page"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tampilkan di atas lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "stopAlarm" -> {
                        AlarmReceiver.stopAlarmStatic(this)
                        result.success(true)
                        finish()
                    }
                    "getNoteId" -> {
                        result.success(intent.getStringExtra("noteId") ?: "")
                    }
                    "getTitle" -> {
                        result.success(intent.getStringExtra("title") ?: "Pengingat")
                    }
                    "getBody" -> {
                        result.success(intent.getStringExtra("body") ?: "")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
