package com.example.expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class ScheduledNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val notificationHelper = NotificationChannelHelper(context)
        notificationHelper.createNotificationChannels()
    }
}

class NotificationChannelHelper(private val context: Context) {
    fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val transactionSyncChannel = NotificationChannel(
                "transaction_sync_channel",
                "Transaction Sync",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for auto-added transactions"
                enableVibration(true)
            }

            val reminderChannel = NotificationChannel(
                "reminder_channel",
                "Reminders",
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminders to add manual transactions"
            }

            val budgetAlertChannel = NotificationChannel(
                "budget_alert_channel",
                "Budget Alerts",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when you exceed your budget"
                enableVibration(true)
            }

            notificationManager.createNotificationChannels(
                listOf(transactionSyncChannel, reminderChannel, budgetAlertChannel)
            )
        }
    }
}