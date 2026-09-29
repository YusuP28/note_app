package com.yusup28.note_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object AlarmScheduler {

    fun schedule(
        context: Context,
        noteId: String,
        title: String,
        body: String,
        triggerAtMillis: Long
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("noteId", noteId)
            putExtra("title", title)
            putExtra("body", body)
        }

        val pi = PendingIntent.getBroadcast(
            context,
            noteId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Coba setAlarmClock (paling kuat, bypass Doze)
        try {
            val showIntent = PendingIntent.getActivity(
                context,
                noteId.hashCode() + 2,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val info = AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent)
            am.setAlarmClock(info, pi)
            return
        } catch (_: SecurityException) {
        }

        // Fallback: setExactAndAllowWhileIdle
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            }
            return
        } catch (_: SecurityException) {
        }

        // Fallback terakhir: inexact
        am.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
    }

    fun cancel(context: Context, noteId: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            noteId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(pi)
        pi.cancel()
    }
}
