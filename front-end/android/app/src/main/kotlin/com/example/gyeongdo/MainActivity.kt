package com.example.gyeongdo

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.carrot.hideseek/geofence"
    private val EVENT_CHANNEL = "com.carrot.hideseek/geofence_events"

    private lateinit var geofencingClient: GeofencingClient
    
    // Static fields for EventChannel
    companion object {
        var eventSink: EventChannel.EventSink? = null
        
        fun enqueueGeofenceEvent(id: String, event: String) {
            val data = mapOf("id" to id, "event" to event)
            if (eventSink != null) {
                // UI Thread에서 실행해야 함
                // 여기서는 간단히 처리하지만 실제로는 Handler 등을 사용해야 할 수 있음.
                // FlutterActivity가 활성 상태일 때만 전달됨.
                try {
                    eventSink?.success(data)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error sending event: ${e.message}")
                }
            } else {
                 Log.w("MainActivity", "EventSink is null, event dropped: $data")
            }
        }
    }

    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(this, GeofenceBroadcastReceiver::class.java)
        intent.action = GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT
        // Android 12+ requires FLAG_MUTABLE or FLAG_IMMUTABLE
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        PendingIntent.getBroadcast(this, 0, intent, flags)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        geofencingClient = LocationServices.getGeofencingClient(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "register" -> {
                    registerGeofence(call, result)
                }
                "remove" -> {
                     removeGeofence(call, result)
                }
                "removeAll" -> {
                    removeAllGeofences(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    @SuppressLint("MissingPermission")
    private fun registerGeofence(call: MethodCall, result: MethodChannel.Result) {
        if (!hasPermissions()) {
            result.error("PERMISSION_DENIED", "Geofence permission denied", null)
            return
        }

        val id = call.argument<String>("id")
        val lat = call.argument<Double>("lat")
        val lng = call.argument<Double>("lng")
        val radius = call.argument<Double>("radius")?.toFloat()

        if (id == null || lat == null || lng == null || radius == null) {
            result.error("INVALID_ARGUMENT", "Missing arguments", null)
            return
        }

        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lng, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent).run {
            addOnSuccessListener {
                result.success(true)
            }
            addOnFailureListener {
                result.error("GEOFENCE_ERROR", it.message, null)
            }
        }
    }
    
    private fun removeGeofence(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        // NOTE: Google Play Services Geofencing doesn't easily support removing by single ID if added in batch,
        // but supports removing by list of IDs.
        
         // Simplified for this example assuming typical usage
         if (id != null) {
              geofencingClient.removeGeofences(listOf(id)).run {
                 addOnSuccessListener { result.success(true) }
                 addOnFailureListener { result.error("REMOVE_ERROR", it.message, null) }
             }
         } else {
             // If ID passed is just string argument
             val idArg = call.arguments as? String
             if (idArg != null) {
                 geofencingClient.removeGeofences(listOf(idArg)).run {
                     addOnSuccessListener { result.success(true) }
                     addOnFailureListener { result.error("REMOVE_ERROR", it.message, null) }
                 }
             } else {
                 result.error("INVALID_ARGUMENT", "ID is null", null)
             }
         }
    }

    private fun removeAllGeofences(result: MethodChannel.Result) {
        geofencingClient.removeGeofences(geofencePendingIntent).run {
            addOnSuccessListener {
                result.success(true)
            }
            addOnFailureListener {
                result.error("REMOVE_ERROR", it.message, null)
            }
        }
    }

    private fun hasPermissions(): Boolean {
        // Check for ACCESS_FINE_LOCATION and ACCESS_BACKGROUND_LOCATION (for Q+)
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
             return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }
}
