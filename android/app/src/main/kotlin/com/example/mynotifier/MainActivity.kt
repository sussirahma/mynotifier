package com.example.mynotifier

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "mynotifier/notification"
    private val EVENT_CHANNEL = "mynotifier/notification_stream"

    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun sendNotificationToFlutter(
            packageName: String,
            title: String,
            text: String
        ) {
            val data = mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "timestamp" to System.currentTimeMillis()
            )

            eventSink?.success(data)
        }
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "isNotificationListenerEnabled" -> {
                    result.success(
                        isNotificationListenerEnabled()
                    )
                }

                "openNotificationSettings" -> {
                    val intent = Intent(
                        "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"
                    )

                    startActivity(intent)

                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event Channel
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(
            object : EventChannel.StreamHandler {

                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    eventSink = events
                }

                override fun onCancel(
                    arguments: Any?
                ) {
                    eventSink = null
                }
            }
        )
    }

    private fun isNotificationListenerEnabled(): Boolean {

        val componentName = ComponentName(
            this,
            NotificationListener::class.java
        )

        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )

        if (enabledListeners.isNullOrEmpty()) {
            return false
        }

        return enabledListeners.contains(
            componentName.flattenToString()
        )
    }
}