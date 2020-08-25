package com.abarajithan.track_me

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.abarajithan.track_me.service.TrackingService.Companion.TRACKING_NOTIFICATION_ID
import com.abarajithan.track_me.service.TrackingService.Companion.TRACKING_NOTIFICATION_NAME
import io.flutter.app.FlutterApplication

class TrackMeApp : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                    TRACKING_NOTIFICATION_ID,
                    TRACKING_NOTIFICATION_NAME,
                    NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}