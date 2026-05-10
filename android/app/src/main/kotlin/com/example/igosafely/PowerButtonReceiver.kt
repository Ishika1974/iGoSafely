package com.example.igosafely

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PowerButtonReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL = "power_button_channel"
        private var pressCount = 0
        private var lastPressTime = 0L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val now = System.currentTimeMillis()
        
        when (intent.action) {
            Intent.ACTION_SCREEN_OFF, 
            Intent.ACTION_SCREEN_ON,
            Intent.ACTION_USER_PRESENT -> {
                // Power button press detected via screen events
                handlePowerButtonPress(context, now)
            }
        }
    }

    private fun handlePowerButtonPress(context: Context, currentTime: Long) {
        val timeDiff = currentTime - lastPressTime
        
        if (timeDiff > 1500) { // Reset if more than 1.5 seconds
            pressCount = 1
        } else {
            pressCount++
        }
        
        lastPressTime = currentTime
        
        // Notify Flutter with press count
        notifyFlutter(context, pressCount)
        
        // Auto-reset after timeout
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (System.currentTimeMillis() - lastPressTime > 1500) {
                pressCount = 0
            }
        }, 2000)
    }

    private fun notifyFlutter(context: Context, pressCount: Int) {
        try {
            // Send broadcast to MainActivity instead of creating FlutterEngine
            val intent = Intent("com.example.igosafely.POWER_BUTTON_PRESSED")
            intent.putExtra("press_count", pressCount)
            context.sendBroadcast(intent)
        } catch (e: Exception) {
            // Fallback: Start emergency service directly
            val intent = Intent(context, BackgroundService::class.java)
            intent.putExtra("press_count", pressCount)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}