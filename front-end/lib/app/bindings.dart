import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/location_service.dart';
import '../services/geofence_service.dart';
import '../view_models/auth_controller.dart';
import '../view_models/room_controller.dart';
import '../view_models/map_editor_controller.dart';
import '../view_models/waiting_room_controller.dart';
import '../view_models/game_controller.dart';

/// 전역 바인딩 (앱 시작 시 초기화되는 서비스)
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services (Singleton)
    Get.put(StorageService(), permanent: true);
    Get.put(ApiService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(GeofenceService(), permanent: true);
  }
}

/// 인증 페이지 바인딩
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}

/// 로비 페이지 바인딩
class LobbyBinding extends Bindings {
  @override
  void dependencies() {
    // 로비에서는 특별한 컨트롤러가 필요 없음
  }
}

/// 방 관련 바인딩 (방 생성, 참여)
class RoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RoomController());
  }
}

/// 지도 편집 바인딩
class MapEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MapEditorController());
  }
}

/// 대기실 바인딩
class WaitingRoomBinding extends Bindings {
  @override
  void dependencies() {
    // SocketService 초기화 (아직 없다면)
    if (!Get.isRegistered<SocketService>()) {
      final socketService = SocketService();
      socketService.init(); // Socket 초기화
      Get.put(socketService, permanent: true);
    }
    Get.lazyPut(() => WaitingRoomController());
  }
}

/// 게임 바인딩
class GameBinding extends Bindings {
  @override
  void dependencies() {
    // SocketService는 이미 초기화되어 있어야 함
    Get.lazyPut(() => GameController());
  }
}
