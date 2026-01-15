import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class GeofenceService extends GetxService {
  static const _methodChannel = MethodChannel('com.carrot.hideseek/geofence');
  static const _eventChannel = EventChannel('com.carrot.hideseek/geofence_events');

  // 이벤트 스트림
  final _onGeofenceEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onGeofenceEvent => _onGeofenceEventController.stream;

  @override
  void onInit() {
    super.onInit();
    _initEventChannel();
  }

  @override
  void onClose() {
    _onGeofenceEventController.close();
    super.onClose();
  }

  void _initEventChannel() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event);
        _onGeofenceEventController.add(data);
        print("Geofence Event Received: $data");
      }
    }, onError: (dynamic error) {
      print("Geofence Event Error: $error");
    });
  }

  /// 활동 구역(Play Area) 등록
  Future<void> registerPlayArea({
    required double centerLat,
    required double centerLng,
    required double radius,
  }) async {
    try {
      await _methodChannel.invokeMethod('register', {
        'id': 'play_area',
        'lat': centerLat,
        'lng': centerLng,
        'radius': radius,
      });
      print("Geofence Registered: play_area ($centerLat, $centerLng, $radius)");
    } on PlatformException catch (e) {
      print("Failed to register play area: ${e.message}");
    }
  }

  /// 감옥(Jail) 등록
  Future<void> registerJail({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      await _methodChannel.invokeMethod('register', {
        'id': 'jail',
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });
      print("Geofence Registered: jail ($lat, $lng, $radius)");
    } on PlatformException catch (e) {
      print("Failed to register jail: ${e.message}");
    }
  }

  /// 특정 Geofence 제거
  Future<void> removeGeofence(String id) async {
    try {
      await _methodChannel.invokeMethod('remove', id);
    } on PlatformException catch (e) {
      print("Failed to remove geofence $id: ${e.message}");
    }
  }

  /// 모든 Geofence 제거
  Future<void> removeAll() async {
    try {
      await _methodChannel.invokeMethod('removeAll');
    } on PlatformException catch (e) {
      print("Failed to remove all geofences: ${e.message}");
    }
  }
}
