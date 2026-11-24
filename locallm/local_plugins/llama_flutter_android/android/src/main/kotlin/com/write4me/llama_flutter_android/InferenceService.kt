package com.write4me.llama_flutter_android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class InferenceService : Service() {
    private val binder = InferenceBinder()
    private val notificationId = 1
    private val channelId = "InferenceServiceChannel"
    private val channelName = "AI Inference Service"
    private val channelDescription = "Foreground service for AI model inference"

    inner class InferenceBinder : Binder() {
        fun getService(): InferenceService = this@InferenceService
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val notification = createNotification().build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    notificationId,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(notificationId, notification)
            }
        } catch (e: Exception) {
            Log.e("InferenceService", "Error in startForeground: $e")
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    private fun createNotification(): NotificationCompat.Builder {
        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Local AI Inference Active")
            .setContentText("Local model loaded and ready")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSound(null)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = channelDescription
                setSound(null, null)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }
}