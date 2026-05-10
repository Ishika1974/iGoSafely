package com.example.igosafely

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.location.LocationManager
import android.os.Handler
import android.os.Looper

class BackgroundService : Service() {
    private val CHANNEL_ID = "iGoSafelyForeground"
    private val NOTIFICATION_ID = 1001
    private var pressCount = 0

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        pressCount = intent?.getIntExtra("press_count", 0) ?: 0
        
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Handle emergency based on press count
        handleEmergencyPress(pressCount)
        
        return START_STICKY // Restart service if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "iGoSafely Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Safety service running in background"
                setSound(null, null)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("iGoSafely Active")
            .setContentText("Monitoring your safety...")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun handleEmergencyPress(count: Int) {
        when (count) {
            2 -> {
                // Send SMS to emergency contacts
                sendEmergencySMS("🚨 EMERGENCY! 2x Power Press\nLocation: [GPS]")
            }
            in 5..10 -> {
                // Critical alert - Police + Contacts
                sendEmergencySMS("🚨 CRITICAL! ${count}x Power Press\nPolice Alert!\nLocation: [GPS]")
                dialEmergency("100")
            }
        }
    }

    private fun sendEmergencySMS(message: String) {
        // Implementation for SMS sending
        val smsIntent = Intent("android.provider.Telephony.SMS_SENT")
        // Add SMS logic here
    }

    private fun dialEmergency(number: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.setData(android.net.Uri.parse("tel:$number"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}