package com.abarajithan.track_me.service

import com.abarajithan.track_me.model.PathLocation

interface BaseTrackingService {
    fun start()
    fun stop()
    fun isTracking(): Boolean
    fun attachListener(listener: ((PathLocation) -> Unit)?)
}