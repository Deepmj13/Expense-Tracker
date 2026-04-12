package com.example.expense_tracker

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class NotificationInterceptorService : NotificationListenerService() {
    private var eventSink: EventChannel.EventSink? = null
    private var monitoredPackages: Set<String> = emptySet()

    companion object {
        const val CHANNEL_NAME = "com.example.expense_tracker/notifications"
        @JvmField var instance: NotificationInterceptorService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        eventSink = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let { notification ->
            if (isMonitored(notification.packageName)) {
                sendNotification(notification)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun setMonitoredPackages(packages: Set<String>) {
        this.monitoredPackages = packages
    }

    private fun isMonitored(packageName: String): Boolean {
        if (monitoredPackages.isEmpty()) return true
        return monitoredPackages.contains(packageName) ||
               monitoredPackages.any { packageName.startsWith("$it.") }
    }

    private fun sendNotification(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""

        val notificationData = mapOf(
            "packageName" to sbn.packageName,
            "title" to title,
            "text" to text,
            "timestamp" to sbn.postTime
        )

        eventSink?.success(notificationData)
    }
}
