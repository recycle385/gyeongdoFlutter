import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../app/constants.dart';

/// 대기실 Controller
class WaitingRoomController extends GetxController {
  final SocketService _socket = Get.find<SocketService>();
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();

  // 방 정보
  final roomInfo = Rx<RoomModel?>(null);
  final roomId = ''.obs;
  final otpCode = ''.obs;

  // 플레이어 목록
  final players = <PlayerModel>[].obs;

  // 현재 사용자
  final mySessionId = ''.obs;
  final myRole = ''.obs; // 'host' or 'player'
  final myTeam = Rx<TeamType>(TeamType.unassigned);

  // 상태
  final isHost = false.obs;
  final isLoading = false.obs;
  final canStartGame = false.obs;

  // OTP 갱신 타이머
  Timer? _otpTimer;
  final otpTimeRemaining = AppConstants.otpRefreshInterval.obs;

  @override
  void onInit() {
    super.onInit();
    _initWaitingRoom();
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    _socket.leaveRoom(roomId.value);
    super.onClose();
  }

  /// 대기실 초기화
  Future<void> _initWaitingRoom() async {
    try {
      // Arguments에서 roomId 가져오기
      final args = Get.arguments as Map<String, dynamic>?;
      roomId.value = args?['roomId'] ?? _storage.roomId ?? '';

      if (roomId.value.isEmpty) {
        throw Exception('방 ID를 찾을 수 없습니다.');
      }

      // 세션 정보
      mySessionId.value = _storage.sessionId ?? '';
      if (mySessionId.value.isEmpty) {
        throw Exception(AppConstants.errorSessionNotFound);
      }

      // Socket 연결
      if (!_socket.isConnected.value) {
        _socket.connect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 방 입장
      _socket.joinRoom(roomId.value, mySessionId.value);

      // Socket 이벤트 구독
      _subscribeToSocketEvents();

      // 방 정보 조회
      await _loadRoomInfo();

      // 방장이면 OTP 갱신 시작
      if (isHost.value) {
        _startOtpTimer();
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  /// Socket 이벤트 구독
  void _subscribeToSocketEvents() {
    // 플레이어 목록 업데이트
    ever(_socket.onPlayersUpdated, (List<PlayerModel> updatedPlayers) {
      players.value = updatedPlayers;
      _updateMyInfo();
      _checkCanStartGame();
    });

    // 역할 배정됨
    ever(_socket.onRoleAssigned, (String? team) {
      if (team != null) {
        myTeam.value = TeamType.fromString(team);
        Get.snackbar(
          '역할 배정',
          '${myTeam.value.label} 역할이 배정되었습니다 ${myTeam.value.emoji}',
          backgroundColor: myTeam.value == TeamType.police
              ? Colors.blue
              : Colors.red,
          colorText: Colors.white,
        );
      }
    });

    // 게임 시작
    ever(_socket.onGameStarted, (Map<String, dynamic>? data) {
      if (data != null) {
        _otpTimer?.cancel();
        Get.offAllNamed('/game', arguments: {
          'roomId': roomId.value,
          'team': myTeam.value.value,
        });
      }
    });
  }

  /// 방 정보 조회
  Future<void> _loadRoomInfo() async {
    try {
      final data = await _api.getRoomInfo(roomId.value);
      roomInfo.value = RoomModel.fromJson(data);

      // 방장 확인
      isHost.value = roomInfo.value?.hostSessionId == mySessionId.value;
      myRole.value = isHost.value ? 'host' : 'player';
    } catch (e) {
      debugPrint('방 정보 조회 실패: $e');
    }
  }

  /// 내 정보 업데이트
  void _updateMyInfo() {
    final me = players.firstWhereOrNull(
      (p) => p.sessionId == mySessionId.value,
    );
    if (me != null) {
      myTeam.value = me.team;
      myRole.value = me.role;
      isHost.value = me.isHost;
    }
  }

  /// 게임 시작 가능 여부 확인
  void _checkCanStartGame() {
    if (!isHost.value) {
      canStartGame.value = false;
      return;
    }

    // 모든 플레이어가 역할 배정되었는지 확인
    final unassigned = players.where((p) => p.team == TeamType.unassigned);
    canStartGame.value = players.length >= 2 && unassigned.isEmpty;
  }

  // ==================== OTP 관리 ====================

  /// OTP 갱신 타이머 시작
  void _startOtpTimer() {
    _refreshOtp(); // 즉시 한 번 호출

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      otpTimeRemaining.value--;

      if (otpTimeRemaining.value <= 0) {
        _refreshOtp();
        otpTimeRemaining.value = AppConstants.otpRefreshInterval;
      }
    });
  }

  /// OTP 갱신
  Future<void> _refreshOtp() async {
    try {
      final newOtp = await _api.refreshOTP(roomId.value);
      otpCode.value = newOtp;
    } catch (e) {
      debugPrint('OTP 갱신 실패: $e');
    }
  }

  // ==================== 역할 배정 (방장 전용) ====================

  /// 역할 토글 (경찰 ↔ 도둑)
  void toggleRole(PlayerModel player) {
    if (!isHost.value) return;
    if (player.sessionId == mySessionId.value) return; // 자기 자신은 변경 불가

    TeamType newTeam;
    if (player.team == TeamType.police) {
      newTeam = TeamType.thief;
    } else if (player.team == TeamType.thief) {
      newTeam = TeamType.police;
    } else {
      newTeam = TeamType.police; // 미배정 → 경찰
    }

    _socket.assignRole(player.sessionId, newTeam.value);
  }

  /// 특정 역할로 지정
  void assignRole(PlayerModel player, TeamType team) {
    if (!isHost.value) return;
    _socket.assignRole(player.sessionId, team.value);
  }

  // ==================== 게임 시작 ====================

  /// 게임 시작 (방장 전용)
  Future<void> startGame() async {
    if (!isHost.value) {
      Get.snackbar('오류', '방장만 게임을 시작할 수 있습니다.');
      return;
    }

    if (!canStartGame.value) {
      Get.snackbar('오류', '모든 플레이어에게 역할을 배정해주세요.');
      return;
    }

    // 경찰과 도둑 수 확인
    final policeCount = players.where((p) => p.team == TeamType.police).length;
    final thiefCount = players.where((p) => p.team == TeamType.thief).length;

    if (policeCount == 0 || thiefCount == 0) {
      Get.snackbar('오류', '경찰과 도둑이 각각 1명 이상 필요합니다.');
      return;
    }

    // 확인 다이얼로그
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('게임 시작'),
        content: Text(
          '게임을 시작하시겠습니까?\n\n'
          '👮 경찰: $policeCount명\n'
          '🦹 도둑: $thiefCount명\n'
          '⏱️ 게임 시간: ${roomInfo.value?.formattedDuration ?? "30분"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _socket.startGame();
    }
  }

  // ==================== 편의 기능 ====================

  /// 팀별 플레이어 카운트
  int get policeCount => players.where((p) => p.team == TeamType.police).length;
  int get thiefCount => players.where((p) => p.team == TeamType.thief).length;
  int get unassignedCount => players.where((p) => p.team == TeamType.unassigned).length;

  /// OTP 복사
  void copyOtp() {
    if (otpCode.value.isEmpty) return;
    // Clipboard.setData(ClipboardData(text: otpCode.value));
    Get.snackbar(
      '복사 완료',
      'OTP 코드가 클립보드에 복사되었습니다.',
      duration: const Duration(seconds: 1),
    );
  }
}
