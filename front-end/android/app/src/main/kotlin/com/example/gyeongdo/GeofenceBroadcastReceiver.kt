package com.example.gyeongdo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import io.flutter.Log

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "GeofenceReceiver"
        const val ACTION_GEOFENCE_EVENT = "com.carrot.hideseek.ACTION_GEOFENCE_EVENT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent!!.hasError()) {
            Log.e(TAG, "Geofencing Error: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition

        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER ||
            geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT
        ) {
            val triggeringGeofences = geofencingEvent.triggeringGeofences
            if (triggeringGeofences != null) {
                for (geofence in triggeringGeofences) {
                    val transitionType = if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) "enter" else "exit"
                    Log.d(TAG, "Geofence Event: ${geofence.requestId} $transitionType")

                    // MainActivity로 전달 (EventChannel용)
                    // 앱이 실행 중이 아닐 때는 처리가 복잡하므로 여기서는 실행 중 가정
                    MainActivity.enqueueGeofenceEvent(geofence.requestId, transitionType)
                }
            }
        } else {
            Log.e(TAG, "Invalid Transition: $geofenceTransition")
        }
    }
}
