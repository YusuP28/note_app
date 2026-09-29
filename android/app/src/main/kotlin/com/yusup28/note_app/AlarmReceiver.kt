package com.yusup28.note_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "note_app_alarm_v4"
        const val CHANNEL_NAME = "Pengingat Catatan"
        const val CHANNEL_DESC = "Notifikasi pengingat catatan"
        private const val TAG = "AlarmReceiver"
        private val RAW_SOUNDS = listOf("sound1", "sound2", "sound3")

        // MediaPlayer global — biar tidak ke-GC sebelum selesai
        private var mediaPlayer: MediaPlayer? = null
        private val stopHandler = Handler(Looper.getMainLooper())
    }

    override fun onReceive(context: Context, intent: Intent) {
        val noteId = intent.getStringExtra("noteId") ?: return
        val title = intent.getStringExtra("title") ?: "Pengingat"
        val body = intent.getStringExtra("body") ?: "Waktunya buka catatan"

        Log.d(TAG, "=== ALARM FIRED ===")
        Log.d(TAG, "noteId=$noteId title=$title")

        createChannel(context)

        // Buat intent untuk buka app
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("noteId", noteId)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            noteId.hashCode(),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // === 1. PUTAR SUARA LANGSUNG (bypass channel) ===
        playSound(context)

        // === 2. GETAR ===
        vibrate(context)

        // === 3. TAMPILKAN NOTIF (visual only, tanpa sound channel) ===
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setSilent(true) // <-- jangan bunyi via channel (kita bunyi manual)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(noteId.hashCode(), notification)
            Log.d(TAG, "Notification posted OK")
        } catch (e: SecurityException) {
            Log.e(TAG, "Post failed: ${e.message}")
        }
    }

    // ============ SOUND ============
    private fun playSound(context: Context) {
        try {
            // Stop sound lama kalau ada
            try { mediaPlayer?.stop(); mediaPlayer?.release() } catch (_: Exception) {}
            mediaPlayer = null

            val soundKey = readSoundKey(context)
            Log.d(TAG, "playSound key=$soundKey")

            val media = if (soundKey in RAW_SOUNDS) {
                val resId = context.resources.getIdentifier(soundKey, "raw", context.packageName)
                if (resId != 0) {
                    MediaPlayer.create(context, resId)
                } else null
            } else null

            mediaPlayer = media ?: MediaPlayer.create(
                context,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            )

            mediaPlayer?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setVolume(1.0f, 1.0f)
                isLooping = false
                setOnCompletionListener {
                    Log.d(TAG, "Sound finished")
                    try { it.release() } catch (_: Exception) {}
                    if (mediaPlayer == it) mediaPlayer = null
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                    true
                }
                start()
                Log.d(TAG, "MediaPlayer started OK")
            } ?: Log.e(TAG, "MediaPlayer is null")
        } catch (e: Exception) {
            Log.e(TAG, "playSound error: ${e.message}", e)
        }
    }

    // ============ VIBRATE ============
    private fun vibrate(context: Context) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                        as android.os.VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
            }
            val pattern = longArrayOf(0, 800, 400, 800, 400, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    android.os.VibrationEffect.createWaveform(pattern, -1)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, -1)
            }
            Log.d(TAG, "Vibrate OK")
        } catch (e: Exception) {
            Log.e(TAG, "Vibrate error: ${e.message}")
        }
    }

    // ============ BACA SETTING ============
    private fun readSoundKey(context: Context): String {
        return try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.notification_sound", "sound1") ?: "sound1"
        } catch (_: Exception) {
            "sound1"
        }
    }

    // ============ CHANNEL (visual only) ============
    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = CHANNEL_DESC
            enableVibration(false) // kita getar manual
            setSound(null, null)    // kita bunyi manual
            enableLights(true)
            setShowBadge(true)
        }
        mgr.createNotificationChannel(channel)
        Log.d(TAG, "Channel created (visual only): $CHANNEL_ID")
    }
}
