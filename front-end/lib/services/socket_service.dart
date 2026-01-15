import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../app/constants.dart';
import '../models/player_model.dart';

/// Socket.io 실시간 통신 서비스
class SocketService extends GetxService {
  late IO.Socket socket;

  // 연결 상태
  final isConnected = false.obs;

  // 이벤트 스트림 (다른 컨트롤러에서 구독)
  final onPlayersUpdated = Rx<List<PlayerModel>>([]);
  final onRoleAssigned = Rx<String?>(null);
  final onGameStarted = Rx<Map<String, dynamic>?>(null);
  final onGameTick = Rx<int?>(null);
  final onTimerUpdate = Rx<Map<String, dynamic>?>(null); // 타이머 업데이트 (게임 상태 포함)
  final onPlayerArrested = Rx<Map<String, dynamic>?>(null);
  final onJailbreakTriggered = Rx<Map<String, dynamic>?>(null); // 탈옥 시도 시작
  final onJailbreakSuccess = Rx<Map<String, dynamic>?>(null);
  final onPlayerFreed = Rx<Map<String, dynamic>?>(null); // 플레이어 탈옥 성공
  final onGameEnded = Rx<Map<String, dynamic>?>(null);
  final onArrestRequested = Rx<Map<String, dynamic>?>(null);

  /// 서비스 초기화
  Future<SocketService> init() async {
    _initSocket();
    return this;
  }

  /// Socket 초기화 및 이벤트 리스너 등록
  void _initSocket() {
    socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // 연결 이벤트
    socket.onConnect((_) {
      debugPrint('✅ Socket 연결됨');
      isConnected.value = true;
    });

    socket.onDisconnect((_) {
      debugPrint('❌ Socket 연결 끊김');
      isConnected.value = false;
    });

    socket.onConnectError((data) {
      debugPrint('🔴 Socket 연결 오류: $data');
      isConnected.value = false;
    });

    socket.onError((data) {
      debugPrint('🔴 Socket 오류: $data');
    });

    // 게임 이벤트 리스너 등록
    _registerEventListeners();
  }

  /// 이벤트 리스너 등록
  void _registerEventListeners() {
    // 플레이어 목록 업데이트
    socket.on('players:updated', (data) {
      debugPrint('📋 플레이어 목록 업데이트: $data');
      if (data is List) {
        final players = data.map((p) => PlayerModel.fromJson(p)).toList();
        onPlayersUpdated.value = players;
      }
    });

    // 역할 배정됨
    socket.on('role:assigned', (data) {
      debugPrint('🎭 역할 배정됨: $data');
      if (data is Map<String, dynamic>) {
        onRoleAssigned.value = data['team'] as String?;
      }
    });

    // 게임 시작
    socket.on('game:started', (data) {
      debugPrint('🎮 게임 시작: $data');
      if (data is Map<String, dynamic>) {
        onGameStarted.value = data;
      }
    });

    // 게임 타이머 틱
    socket.on('game:tick', (data) {
      if (data is Map<String, dynamic>) {
        final remainingTime = data['remainingTime'] as int?;
        if (remainingTime != null) {
          onGameTick.value = remainingTime;
        }
        // 타이머 업데이트 (게임 상태 포함)
        onTimerUpdate.value = data;
      }
    });

    // 플레이어 체포됨
    socket.on('player:arrested', (data) {
      debugPrint('👮 플레이어 체포됨: $data');
      if (data is Map<String, dynamic>) {
        onPlayerArrested.value = data;
      }
    });

    // 자동 체포 (영역 이탈)
    socket.on('player:auto_arrested', (data) {
      debugPrint('⚠️ 자동 체포: $data');
      if (data is Map<String, dynamic>) {
        onPlayerArrested.value = data;
      }
    });

    // 탈옥 시도 시작
    socket.on('jailbreak:triggered', (data) {
      debugPrint('🚪 탈옥 시도 시작: $data');
      if (data is Map<String, dynamic>) {
        onJailbreakTriggered.value = data;
      }
    });

    // 탈옥 성공
    socket.on('jailbreak:success', (data) {
      debugPrint('🚨 탈옥 성공: $data');
      if (data is Map<String, dynamic>) {
        onJailbreakSuccess.value = data;
        onPlayerFreed.value = data; // 호환성
      }
    });

    // 게임 종료
    socket.on('game:ended', (data) {
      debugPrint('🏁 게임 종료: $data');
      if (data is Map<String, dynamic>) {
        onGameEnded.value = data;
      }
    });

    // 검거 요청 받음
    socket.on('arrest:requested', (data) {
      debugPrint('🚔 검거 요청 받음: $data');
      if (data is Map<String, dynamic>) {
        onArrestRequested.value = data;
      }
    });

    // 에러 이벤트
    socket.on('error', (data) {
      debugPrint('🔴 서버 에러: $data');
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? '알 수 없는 오류';
        Get.snackbar('오류', message);
      }
    });
  }

  // ==================== 연결 관리 ====================

  /// Socket 연결
  void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  /// Socket 연결 해제
  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }

  // ==================== 방 입장/퇴장 ====================

  /// 방 입장
  void joinRoom(String roomId, String sessionId) {
    socket.emit('room:join', {
      'roomId': roomId,
      'sessionId': sessionId,
    });
    debugPrint('🚪 방 입장: roomId=$roomId, sessionId=$sessionId');
  }

  /// 방 나가기
  void leaveRoom(String roomId) {
    socket.emit('room:leave', {'roomId': roomId});
    debugPrint('🚪 방 나감: roomId=$roomId');
  }

  // ==================== 대기실 ====================

  /// 역할 배정 (방장만)
  void assignRole(String targetSessionId, String team) {
    socket.emit('role:assign', {
      'targetSessionId': targetSessionId,
      'team': team,
    });
    debugPrint('🎭 역할 배정: $targetSessionId → $team');
  }

  /// 게임 시작 (방장만)
  void startGame() {
    socket.emit('game:start');
    debugPrint('🎮 게임 시작 요청');
  }

  // ==================== 게임 중 ====================

  /// 검거 요청 (경찰)
  void requestArrest(String targetSessionId) {
    socket.emit('arrest:request', {
      'targetSessionId': targetSessionId,
    });
    debugPrint('👮 검거 요청: $targetSessionId');
  }

  /// 검거 응답 (도둑)
  void respondArrest(String requestId, bool accepted) {
    socket.emit('arrest:respond', {
      'requestId': requestId,
      'accepted': accepted,
    });
    debugPrint('🦹 검거 응답: $requestId → ${accepted ? "인정" : "거절"}');
  }

  /// 영역 이탈 알림
  void notifyBoundaryExit() {
    socket.emit('boundary:exit');
    debugPrint('⚠️ 영역 이탈 알림');
  }

  /// 영역 복귀 알림
  void notifyBoundaryEnter() {
    socket.emit('boundary:enter');
    debugPrint('✅ 영역 복귀 알림');
  }

  /// 탈옥 시도 (도둑)
  void triggerJailbreak() {
    socket.emit('jailbreak:trigger');
    debugPrint('🚨 탈옥 시도');
  }

  /// 채팅 메시지 전송 (도둑 간)
  void sendChat(String targetSessionId, String message) {
    socket.emit('chat:send', {
      'targetSessionId': targetSessionId,
      'message': message,
    });
    debugPrint('💬 채팅 전송: $targetSessionId → $message');
  }

  /// 위치 업데이트 (선택적)
  void updateLocation(double lat, double lng, double distance, int steps) {
    socket.emit('location:update', {
      'lat': lat,
      'lng': lng,
      'distance': distance,
      'steps': steps,
    });
  }

  // ==================== Cleanup ====================

  @override
  void onClose() {
    disconnect();
    socket.dispose();
    super.onClose();
  }
}
