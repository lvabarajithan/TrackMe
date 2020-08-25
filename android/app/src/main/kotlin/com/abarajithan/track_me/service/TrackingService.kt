package com.abarajithan.track_me.service

import android.Manifest
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.icu.text.SimpleDateFormat
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Binder
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import com.abarajithan.track_me.R
import com.abarajithan.track_me.model.PathLocation
import java.util.*

private const val GPS_TRACKING_IN_MILLIS = 1000L
private const val GPS_TRACKING_IN_DISTANCE_METERS = 1f

class TrackingService : Service(), BaseTrackingService, LocationListener {

    companion object {
        const val NOTIFICATION_ID = 101
        const val TRACKING_NOTIFICATION_ID = "tracking_notif"
        const val TRACKING_NOTIFICATION_NAME = "Tracking Notification"
    }

    private var listener: ((PathLocation) -> Unit)? = null
    private var isTracking = false
    private lateinit var locationManager: LocationManager
    val pathList = mutableListOf<Location>()

    var startTimestamp: Long = 0

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    override fun onBind(p0: Intent?): IBinder? = LocalBinder()

    override fun start() {
        startTimestamp = System.currentTimeMillis()
        pathList.clear()
        startForegroundNotification()
        initLocationTracking()
    }

    override fun stop() {
        stopLocationUpdates()
        stopForeground(true)
        stopSelf()
    }

    override fun attachListener(listener: ((PathLocation) -> Unit)?) {
        this.listener = listener
    }

    override fun isTracking() = isTracking

    override fun onLocationChanged(location: Location) {
        val pathLocation = PathLocation.fromLocation(location)
        listener?.invoke(pathLocation)
        pathList.add(location)
    }

    override fun onStatusChanged(p0: String?, p1: Int, p2: Bundle?) {
        //
    }

    override fun onProviderEnabled(p0: String?) {
        //
    }

    override fun onProviderDisabled(p0: String?) {
        //
    }

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val time = SimpleDateFormat("hh:mm aa", Locale.getDefault())
                    .format(Date(startTimestamp))
            val builder = Notification.Builder(this, TRACKING_NOTIFICATION_ID)
                    .setContentTitle("Tracking..")
                    .setContentText("Started at $time")
                    .setSmallIcon(R.drawable.ic_baseline_navigation)
            startForeground(NOTIFICATION_ID, builder.build())
        }
    }

    private fun getLocationCriteria() = Criteria().apply {
        accuracy = Criteria.ACCURACY_FINE
        powerRequirement = Criteria.POWER_HIGH
        isAltitudeRequired = false
        isSpeedRequired = true
        isCostAllowed = true
        isBearingRequired = false
        horizontalAccuracy = Criteria.ACCURACY_HIGH
        verticalAccuracy = Criteria.ACCURACY_HIGH
    }

    private fun initLocationTracking() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) return
        }
        isTracking = true
        locationManager.requestLocationUpdates(
                GPS_TRACKING_IN_MILLIS,
                GPS_TRACKING_IN_DISTANCE_METERS,
                getLocationCriteria(),
                this,
                null
        )
    }

    private fun stopLocationUpdates() {
        isTracking = false
        locationManager.removeUpdates(this)
    }

    inner class LocalBinder : Binder() {
        fun getService(): TrackingService = this@TrackingService
    }

}