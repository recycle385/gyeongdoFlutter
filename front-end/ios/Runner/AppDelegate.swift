import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate, FlutterStreamHandler {
  
  private var locationManager: CLLocationManager?
  private var eventSink: FlutterEventSink?
  private let geofenceChannelName = "com.carrot.hideseek/geofence"
  private let eventChannelName = "com.carrot.hideseek/geofence_events"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: geofenceChannelName,
                                              binaryMessenger: controller.binaryMessenger)
    
    let eventChannel = FlutterEventChannel(name: eventChannelName,
                                            binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)
    
    methodChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      self.handleMethodCall(call: call, result: result)
    })
    
    initLocationManager()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  private func initLocationManager() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestAlwaysAuthorization()
    locationManager?.allowsBackgroundLocationUpdates = true
    locationManager?.pausesLocationUpdatesAutomatically = false
  }
    
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "register" {
         guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let lat = args["lat"] as? Double,
              let lng = args["lng"] as? Double,
              let radius = args["radius"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments missing", details: nil))
            return
         }
         
         let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
         let region = CLCircularRegion(center: center, radius: radius, identifier: id)
         region.notifyOnEntry = true
         region.notifyOnExit = true
         
         locationManager?.startMonitoring(for: region)
         result(true)
         
    } else if call.method == "remove" {
        if let id = call.arguments as? String {
             if let region = locationManager?.monitoredRegions.first(where: { $0.identifier == id }) {
                 locationManager?.stopMonitoring(for: region)
                 result(true)
             } else {
                 result(true) // Already removed or not found
             }
        } else {
             result(FlutterError(code: "INVALID_ARGUMENT", message: "ID missing", details: nil))
        }
        
    } else if call.method == "removeAll" {
         if let regions = locationManager?.monitoredRegions {
             for region in regions {
                 locationManager?.stopMonitoring(for: region)
             }
         }
         result(true)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
    
  // MARK: - FlutterStreamHandler
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      self.eventSink = events
      return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
      self.eventSink = nil
      return nil
  }
    
  // MARK: - CLLocationManagerDelegate
    
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
      if let sink = eventSink {
          sink(["id": region.identifier, "event": "enter"])
      }
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
      if let sink = eventSink {
          sink(["id": region.identifier, "event": "exit"])
      }
  }
    
  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
      print("Started monitoring for region: \(region.identifier)")
  }
    
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
      print("Monitoring failed for region: \(region?.identifier ?? "nil"), error: \(error.localizedDescription)")
  }
}
