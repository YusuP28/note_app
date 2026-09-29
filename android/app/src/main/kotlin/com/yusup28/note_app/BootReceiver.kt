package com.yusup28.note_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            // Placeholder — alarm di-restore dari Flutter saat app buka
            // (untuk lengkap: baca SharedPreferences & reschedule)
        }
    }
}
