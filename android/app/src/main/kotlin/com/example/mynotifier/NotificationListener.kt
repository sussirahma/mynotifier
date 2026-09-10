package com.example.mynotifier

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)

        if (sbn == null) return

        val packageName = sbn.packageName
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras.getString(
            Notification.EXTRA_TITLE
        ) ?: ""

        val text = extras.getCharSequence(
            Notification.EXTRA_TEXT
        )?.toString() ?: ""

        Log.d("MyNotifier", "Package: $packageName")
        Log.d("MyNotifier", "Title: $title")
        Log.d("MyNotifier", "Text: $text")

        // Kirim notifikasi ke Flutter
        MainActivity.sendNotificationToFlutter(
            packageName,
            title,
            text
        )
    }
}