package com.abarajithan.track_me

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import com.abarajithan.track_me.model.toJson
import com.abarajithan.track_me.service.TrackingService
import com.abarajithan.track_me.util.DartCall
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.text.SimpleDateFormat
import java.util.*

private const val METHOD_CHANNEL = "com.abarajithan.track_me/comm"
private const val RC_PERMISSIONS = 101

class MainActivity : FlutterActivity() {

    private var trackingService: TrackingService? = null
    private lateinit var connection: ServiceConnection
    private var serviceBound = false
    private var serviceBoundResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        setUpMethodChannelListener(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        _bindService {
            trackingService?.attachListener { location ->
                location.toJson()?.let { invokePathLocation(it) }
            }
            serviceBound = true
            serviceBoundResult?.let {
                it.success(true)
                serviceBoundResult = null
            }
        }

        requestPermission()
    }

    private fun invokePathLocation(pathLocation: String) {
        val messenger = flutterEngine!!.dartExecutor.binaryMessenger
        MethodChannel(messenger, METHOD_CHANNEL)
                .invokeMethod(DartCall.PATH_LOCATION, pathLocation)
    }

    override fun onStop() {
        super.onStop()
        trackingService?.let {
            it.attachListener(null)
            unbindService(connection)
            serviceBound = false
        }
    }

    private fun _bindService(handler: () -> Unit) {
        connection = object : ServiceConnection {
            override fun onServiceDisconnected(name: ComponentName?) {
                trackingService = null
            }

            override fun onServiceConnected(name: ComponentName?, serviceBinder: IBinder?) {
                val binder = serviceBinder as TrackingService.LocalBinder
                trackingService = binder.getService()
                handler()
            }
        }
        val intent = Intent(this, TrackingService::class.java)
        startService(intent)
        bindService(intent, connection, Context.BIND_AUTO_CREATE)
    }

    private fun setUpMethodChannelListener(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                DartCall.START_TRACKING -> {
                    startTrackingService()
                    val time = SimpleDateFormat("hh:mm aa", Locale.getDefault())
                            .format(Date(trackingService!!.startTimestamp))
                    result.success(time)
                }
                DartCall.GET_TRACKED_POINTS -> {
                    val paths = trackingService?.pathList
                    val latLong = paths?.map { listOf(it.latitude, it.longitude) }
                    result.success(Gson().toJson(latLong))
                }
                DartCall.STOP_TRACKING -> {
                    stopTrackingService()
                    result.success(System.currentTimeMillis() - trackingService!!.startTimestamp)
                }
                DartCall.IS_TRACKING_ENABLED -> {
                    result.success(isTracking())
                }
                DartCall.SERVICE_BOUND -> {
                    if (trackingService != null) {
                        result.success(serviceBound)
                        return@setMethodCallHandler
                    }
                    serviceBoundResult = result
                }
                DartCall.START_TIME -> {
                    trackingService?.let {
                        val time = SimpleDateFormat("hh:mm aa", Locale.getDefault())
                                .format(Date(it.startTimestamp))
                        result.success(time)
                    }
                }
                DartCall.HAS_PROPER_PERMISSION -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        (checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                                == PackageManager.PERMISSION_GRANTED)
                    } else true
                    result.success(granted)
                }
                DartCall.LAUNCH_APP_SETTINGS -> {
                    with(Intent()) {
                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        val uri = Uri.fromParts("package", activity.packageName, null)
                        data = uri
                        startActivity(this)
                    }
                    result.success(true)
                }
            }
        }
    }

    private fun startTrackingService() {
        if (requestPermission()) {
            return
        }
        startService(Intent(this, TrackingService::class.java))
        trackingService?.start()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RC_PERMISSIONS) {
            val granted = (grantResults[0] == Activity.RESULT_OK)
                    && (grantResults[1] == Activity.RESULT_OK)
                    && (grantResults[2] == Activity.RESULT_OK)
            if (granted) {
                startTrackingService()
            }
        }
    }

    private fun stopTrackingService() {
        trackingService?.stop()
    }

    private fun isTracking() = trackingService?.isTracking() ?: false

    private fun requestPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if ((checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                            != PackageManager.PERMISSION_GRANTED)
                    && (checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
                            != PackageManager.PERMISSION_GRANTED)
                    && (checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                            != PackageManager.PERMISSION_GRANTED)) {
                requestPermissions(arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ), RC_PERMISSIONS)
                return true
            }
        }
        return false
    }

}