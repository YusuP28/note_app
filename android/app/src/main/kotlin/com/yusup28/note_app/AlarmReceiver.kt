package com.yusup28.note_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "note_app_alarm_v5"
        const val CHANNEL_NAME = "Pengingat Catatan"
        const val CHANNEL_DESC = "Notifikasi pengingat dengan alarm"
        const val ACTION_STOP = "com.yusup28.note_app.ACTION_STOP_ALARM"
        const val AUTO_STOP_MS = 60_000L // auto-stop setelah 60 detik
        private const val TAG = "AlarmReceiver"
        private val RAW_SOUNDS = listOf("sound1", "sound2", "sound3")

        // Global — biar bisa di-stop dari StopReceiver
        @Volatile
        var currentPlayer: MediaPlayer? = null
        private var stopHandler: Handler? = null
        private var currentNoteId: String? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Cek kalau ini intent STOP dari notif
        if (intent.action == ACTION_STOP) {
            stopAlarm(context)
            return
        }

        val noteId = intent.getStringExtra("noteId") ?: return
        val title = intent.getStringExtra("title") ?: "Pengingat"
        val body = intent.getStringExtra("body") ?: "Waktunya buka catatan"

        Log.d(TAG, "=== ALARM FIRED === noteId=$noteId")
        currentNoteId = noteId

        // Stop sound lama (kalau ada alarm sebelumnya)
        stopAlarm(context)

        createChannel(context)

        // Intent buka app saat notif ditap
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

        // Full-screen intent
        val fullScreenIntent = PendingIntent.getActivity(
            context,
            noteId.hashCode() + 1,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent STOP (tombol "Matikan" di notif)
        val stopIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            noteId.hashCode() + 2,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // PLAY SOUND (loop!)
        playSoundLooping(context)

        // VIBRATE
        vibrate(context)

        // NOTIF dengan action button
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false) // jangan auto-dismiss
            .setOngoing(true)     // tetap sampai user matikan
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .setSilent(true)      // sound manual (bukan via channel)
            .addAction(
                R.mipmap.ic_launcher,
                "MATIKAN",
                stopPendingIntent
            )
            .build()

        try {
            NotificationManagerCompat.from(context).notify(noteId.hashCode(), notification)
            Log.d(TAG, "Notification posted OK (loop)")
        } catch (e: SecurityException) {
            Log.e(TAG, "Post failed: ${e.message}")
        }

        // Auto-stop 60 detik (safety)
        stopHandler = Handler(Looper.getMainLooper())
        stopHandler?.postDelayed({
            Log.d(TAG, "AUTO-STOP after ${AUTO_STOP_MS}ms")
            stopAlarm(context)
        }, AUTO_STOP_MS)
    }

    // ============ STOP ALARM ============
    private fun stopAlarm(context: Context) {
        try {
            currentPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {}
        currentPlayer = null

        stopHandler?.removeCallbacksAndMessages(null)
        stopHandler = null

        // Cancel notif
        currentNoteId?.let {
            try {
                NotificationManagerCompat.from(context).cancel(it.hashCode())
            } catch (_: Exception) {}
        }
        currentNoteId = null

        Log.d(TAG, "Alarm stopped")
    }

    // ============ SOUND (loop) ============
    private fun playSoundLooping(context: Context) {
        try {
            val soundKey = readSoundKey(context)
            val media = if (soundKey in RAW_SOUNDS) {
                val resId = context.resources.getIdentifier(soundKey, "raw", context.packageName)
                if (resId != 0) MediaPlayer.create(context, resId) else null
            } else null

            val player = media ?: MediaPlayer.create(
                context,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            )

            player?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setVolume(1.0f, 1.0f)
                isLooping = true // LOOP!
                start()
                Log.d(TAG, "MediaPlayer loop started (key=$soundKey)")
            }
            currentPlayer = player
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
            val pattern = longArrayOf(0, 800, 400, 800, 400, 800, 400, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(android.os.VibrationEffect.createWaveform(pattern, 0)) // loop juga
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Vibrate error: ${e.message}")
        }
    }

    private fun readSoundKey(context: Context): String {
        return try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.notification_sound", "sound1") ?: "sound1"
        } catch (_: Exception) { "sound1" }
    }

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
            enableVibration(false)
            setSound(null, null)
            enableLights(true)
            setShowBadge(true)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        }
        mgr.createNotificationChannel(channel)
        Log.d(TAG, "Channel created: $CHANNEL_ID")
    }
}
