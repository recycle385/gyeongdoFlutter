import 'dart:async';
import 'package:location/location.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {
  final Location _location = Location();
  
  // 위치 스트림
  final _locationController = StreamController<LocationData>.broadcast();
  Stream<LocationData> get onLocationChanged => _locationController.stream;
  
  // 현재 위치 캐시
  final currentLocation = Rx<LocationData?>(null);
  final isTracking = false.obs;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void onInit() {
    super.onInit();
    init();
  }
  
  @override
  void onClose() {
    stopTracking();
    _locationController.close();
    super.onClose();
  }

  Future<void> init() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 1. 서비스 활성화 확인
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // 2. 권한 확인
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    
    // 설정: 정확도 높음, 인터벌 5초, 거리 0m (모든 변화 감지하되 인터벌로 조절)
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 5000,
      distanceFilter: 0,
    );
    
    // 초기 위치
    final locationData = await _location.getLocation();
    currentLocation.value = locationData;
  }

  void startTracking() {
    if (isTracking.value) return;
    
    isTracking.value = true;
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      this.currentLocation.value = currentLocation;
      _locationController.add(currentLocation);
      // print('Location: ${currentLocation.latitude}, ${currentLocation.longitude}');
    });
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    isTracking.value = false;
  }
  
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}
