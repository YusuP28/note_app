package com.yusup28.note_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        // Channel per-suara: suara channel Android 8+ immutable, jadi ID beda tiap suara
        const val CHANNEL_PREFIX = "note_app_alarm_v3_"
        const val CHANNEL_NAME = "Pengingat Catatan"
        const val CHANNEL_DESC = "Notifikasi pengingat seperti alarm"
        private const val TAG = "AlarmReceiver"
        private val RAW_SOUNDS = listOf("sound1", "sound2", "sound3")
        private val VIBRATION = longArrayOf(0, 800, 400, 800, 400, 800)
    }

    override fun onReceive(context: Context, intent: Intent) {
        val noteId = intent.getStringExtra("noteId") ?: return
        val title = intent.getStringExtra("title") ?: "Pengingat"
        val body = intent.getStringExtra("body") ?: "Waktunya buka catatan"

        Log.d(TAG, "Alarm fired: $noteId $title")

        val soundKey = readSoundKey(context)
        val soundUri = resolveSound(context, soundKey)
        val channelId = CHANNEL_PREFIX + (if (soundKey in RAW_SOUNDS) soundKey else "default")
        Log.d(TAG, "soundKey=$soundKey uri=$soundUri channel=$channelId")

        createChannel(context, channelId, soundUri)

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
        val fullScreenIntent = PendingIntent.getActivity(
            context,
            noteId.hashCode() + 1,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(soundUri)
            .setVibrate(VIBRATION)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .setOnlyAlertOnce(false)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(noteId.hashCode(), notification)
            Log.d(TAG, "Notification posted OK")
        } catch (e: SecurityException) {
            Log.e(TAG, "Post failed: ${e.message}")
        }
    }

    // Baca pilihan suara dari SharedPreferences Flutter (key: notification_sound)
    private fun readSoundKey(context: Context): String {
        return try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.notification_sound", "sound1") ?: "sound1"
        } catch (e: Exception) {
            "sound1"
        }
    }

    private fun resolveSound(context: Context, key: String): Uri {
        if (key in RAW_SOUNDS) {
            val resId = context.resources.getIdentifier(key, "raw", context.packageName)
            if (resId != 0) return Uri.parse("android.resource://${context.packageName}/$resId")
            Log.e(TAG, "Raw resource $key tidak ditemukan, pakai default")
        }
        return defaultUri()
    }

    // Fallback: ALARM -> RINGTONE -> NOTIFICATION
    private fun defaultUri(): Uri = try {
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    } catch (e: Exception) {
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun createChannel(context: Context, channelId: String, soundUri: Uri) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Hapus channel lama supaya tidak stuck dengan config lama
        for (old in listOf("note_app_alarm_v1", "note_app_alarm_v2")) {
            try { mgr.deleteNotificationChannel(old) } catch (_: Exception) {}
        }

        if (mgr.getNotificationChannel(channelId) != null) return

        val channel = NotificationChannel(
            channelId,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = CHANNEL_DESC
            enableVibration(true)
            vibrationPattern = VIBRATION
            enableLights(true)
            lightColor = 0xFF6750A4.toInt()
            setShowBadge(true)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC

            val attrs = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()
            setSound(soundUri, attrs)
        }
        mgr.createNotificationChannel(channel)
        Log.d(TAG, "Channel created: $channelId with sound $soundUri")
    }
}
