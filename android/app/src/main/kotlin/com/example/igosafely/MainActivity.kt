package com.example.igosafely

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
import android.os.Bundle
import android.view.KeyEvent
import androidx.annotation.NonNull

class BackgroundPowerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.igosafely.POWER_BUTTON_PRESSED") {
            val pressCount = intent.getIntExtra("press_count", 0)
            // Send the press count to Flutter via a static method or stored reference
            MainActivity.handlePowerButtonPress(pressCount)
        }
    }
}

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "power_button_channel"
    private val LOCATION_CHANNEL = "location_channel"
    private var powerManager: PowerManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var powerButtonReceiver: PowerButtonReceiver? = null
    private var backgroundReceiver: BackgroundPowerReceiver? = null

    companion object {
        private var currentInstance: MainActivity? = null
        
        fun handlePowerButtonPress(pressCount: Int) {
            currentInstance?.let { activity ->
                activity.runOnUiThread {
                    try {
                        val messenger = activity.flutterEngine?.dartExecutor?.binaryMessenger
                        if (messenger != null) {
                            MethodChannel(messenger, "power_button_channel")
                                .invokeMethod("power_button_pressed", pressCount)
                        }
                    } catch (e: Exception) {
                        // Handle error
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        currentInstance = this
        
        powerManager = getSystemService(POWER_SERVICE) as PowerManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPowerButtonListener" -> {
                    startPowerButtonMonitoring()
                    result.success("Power button listener started")
                }
                "stopPowerButtonListener" -> {
                    stopPowerButtonMonitoring()
                    result.success("Power button listener stopped")
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startPowerButtonMonitoring() {
        // Acquire wake lock for reliable power button detection
        wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "iGoSafely::PowerButtonWakeLock"
        )
        wakeLock?.acquire(30*60*1000L /*30 minutes*/)

        // Register broadcast receiver for screen events (power button proxy)
        powerButtonReceiver = PowerButtonReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(powerButtonReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(powerButtonReceiver, filter)
        }

        // Register receiver for power button press broadcasts from PowerButtonReceiver
        backgroundReceiver = BackgroundPowerReceiver()
        val backgroundFilter = IntentFilter("com.example.igosafely.POWER_BUTTON_PRESSED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(backgroundReceiver, backgroundFilter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(backgroundReceiver, backgroundFilter)
        }
    }

    private fun stopPowerButtonMonitoring() {
        powerButtonReceiver?.let { unregisterReceiver(it) }
        backgroundReceiver?.let { unregisterReceiver(it) }
        wakeLock?.release()
    }

    private fun requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                android.net.Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun getBatteryLevel(): Int {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = registerReceiver(null, intentFilter)
        val level: Int = batteryStatus?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level != -1 && scale != -1) (level * 100 / scale.toFloat()).toInt() else -1
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Direct power button handling (fallback)
        if (keyCode == KeyEvent.KEYCODE_POWER) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("power_button_pressed", null)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        stopPowerButtonMonitoring()
        super.onDestroy()
    }
}