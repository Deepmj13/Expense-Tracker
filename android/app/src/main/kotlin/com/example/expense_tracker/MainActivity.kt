package com.example.expense_tracker

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.example.expense_tracker/notifications"
    private val METHOD_CHANNEL = "com.example.expense_tracker/methods"
    private var notificationEventChannel: EventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        notificationEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        )

        notificationEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NotificationInterceptorService.instance?.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                NotificationInterceptorService.instance?.setEventSink(null)
            }
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessEnabled" -> {
                    result.success(isNotificationAccessGranted())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "getNotificationAccessSettingsIntent" -> {
                    result.success(getNotificationAccessIntent())
                }
                "setMonitoredApps" -> {
                    val packages = call.arguments as? List<String>
                    NotificationInterceptorService.instance?.setMonitoredPackages(packages?.toSet() ?: emptySet())
                    result.success(null)
                }
                "isBatteryOptimizationDisabled" -> {
                    result.success(isBatteryOptimizationDisabled())
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                "requestBatteryOptimizationExemption" -> {
                    requestBatteryOptimizationExemption()
                    result.success(null)
                }
                "getDeviceManufacturer" -> {
                    result.success(Build.MANUFACTURER.lowercase())
                }
                "openAutoStartSettings" -> {
                    openAutoStartSettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val componentName = ComponentName(this, NotificationInterceptorService::class.java)
        val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return enabledListeners?.contains(componentName.flattenToString()) == true
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getNotificationAccessIntent(): Map<String, String?> {
        return mapOf(
            "action" to Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS,
            "package" to packageName
        )
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    private fun requestBatteryOptimizationExemption() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            openBatteryOptimizationSettings()
        }
    }

    private fun openAutoStartSettings() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        
        val intents = mutableListOf<Intent>()
        
        when {
            manufacturer.contains("xiaomi") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.powercenter.PowerSettings"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("samsung") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.battery.ui.BatteryActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.samsung.android.sm",
                        "com.samsung.android.sm.battery.ui.BatteryActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.optimize.process.ProtectActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("oppo") || manufacturer.contains("realme") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.oppo.safe",
                        "com.oppo.safe.permission.startup.StartupAppListActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("vivo") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("oneplus") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.oneplus.security",
                        "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("asus") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.asus.mobilemanager",
                        "com.asus.mobilemanager.autostart.AutoStartActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
            manufacturer.contains("letv") || manufacturer.contains("leeco") -> {
                intents.add(Intent().apply {
                    component = ComponentName(
                        "com.letv.android.letvsafe",
                        "com.letv.android.letvsafe.AutobootManageActivity"
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
            }
        }
        
        for (intent in intents) {
            try {
                if (packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                    startActivity(intent)
                    return
                }
            } catch (e: Exception) {
                continue
            }
        }
        
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
}
