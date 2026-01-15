import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/constants.dart';
import '../app/theme.dart';
import '../models/game_state_model.dart';
import '../models/player_model.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../app/routes.dart';
import '../services/location_service.dart';
import '../services/geofence_service.dart';

/// 게임 공통 컨트롤러 (경찰/도둑 공통 로직)
class GameController extends GetxController {
  final SocketService _socketService = Get.find<SocketService>();
  final StorageService _storage = Get.find<StorageService>();
  final LocationService _locationService = Get.find<LocationService>();
  final GeofenceService _geofenceService = Get.find<GeofenceService>();

  // 게임 상태
  final Rx<GameStateModel?> gameState = Rx<GameStateModel?>(null);
  final RxList<PlayerModel> players = <PlayerModel>[].obs;

  // 내 정보
  final myTeam = TeamType.unassigned.obs;
  final myStatus = PlayerStatus.alive.obs;
  final mySessionId = ''.obs;

  // 위치 추적
  Timer? _locationTimer;
  double? _lastLat;
  double? _lastLng;

  // 위치 getter (외부 접근용)
  double? get currentLat => _lastLat;
  double? get currentLng => _lastLng;

  // 검거 관련
  final arrestRequestedBy = Rx<String?>(null); // 누가 나를 검거하려고 하는지
  final arrestTimeRemaining = 0.obs; // 검거 응답 남은 시간
  Timer? _arrestTimer;

  // 탈옥 관련
  final jailbreakInProgress = false.obs;
  final jailbreakTimeRemaining = 0.obs;
  Timer? _jailbreakTimer;

  @override
  void onInit() {
    super.onInit();
    _initController();
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    _arrestTimer?.cancel();
    _jailbreakTimer?.cancel();
    super.onClose();
  }

  /// 컨트롤러 초기화
  void _initController() {
    mySessionId.value = _storage.sessionId ?? '';
    _subscribeToSocketEvents();
  }

  /// Socket 이벤트 구독
  void _subscribeToSocketEvents() {
    // 게임 시작
    ever(_socketService.onGameStarted, (data) {
      if (data != null) {
        _handleGameStarted(data);
      }
    });

    // 타이머 업데이트
    ever(_socketService.onTimerUpdate, (data) {
      if (data != null) {
        _handleTimerUpdate(data);
      }
    });

    // 플레이어 업데이트
    ever(_socketService.onPlayersUpdated, (updatedPlayers) {
      players.value = updatedPlayers;
      _updateMyStatus();
    });

    // 검거 요청 받음 (도둑이 받음)
    ever(_socketService.onArrestRequested, (data) {
      if (data != null && myTeam.value == TeamType.thief) {
        _handleArrestRequested(data);
      }
    });

    // 플레이어 체포됨
    ever(_socketService.onPlayerArrested, (data) {
      if (data != null) {
        _handlePlayerArrested(data);
      }
    });

    // 탈옥 시도
    ever(_socketService.onJailbreakTriggered, (data) {
      if (data != null) {
        _handleJailbreakTriggered(data);
      }
    });

    // 플레이어 탈옥 성공
    ever(_socketService.onPlayerFreed, (data) {
      if (data != null) {
        _handlePlayerFreed(data);
      }
    });

    // 게임 종료
    ever(_socketService.onGameEnded, (data) {
      if (data != null) {
        _handleGameEnded(data);
      }
    });
  }

  /// 게임 시작 처리
  void _handleGameStarted(Map<String, dynamic> data) {
    debugPrint('🎮 게임 시작됨: $data');

    // 내 팀 확인
    final players = (data['players'] as List?)
        ?.map((p) => PlayerModel.fromJson(p))
        .toList() ?? [];

    final me = players.firstWhereOrNull((p) => p.sessionId == mySessionId.value);
    if (me != null) {
      myTeam.value = me.team;
      myStatus.value = me.status;
    }

    // 게임 상태 초기화
    gameState.value = GameStateModel.fromJson(data['gameState'] ?? {});

    // 위치 추적 시작
    _startLocationTracking();

    // Geofence 등록 (실제로는 방 정보에서 받아와야 함)
    // _geofenceService.registerPlayArea(...);

    // 역할에 따라 화면 이동
    Get.offAllNamed(Routes.GAME, arguments: {
      'team': myTeam.value,
    });
  }

  /// 타이머 업데이트 처리
  void _handleTimerUpdate(Map<String, dynamic> data) {
    final newState = GameStateModel.fromJson(data);
    gameState.value = newState;

    // 시간 종료 체크
    if (newState.isTimeUp) {
      debugPrint('⏰ 시간 종료!');
    }
  }

  /// 내 상태 업데이트
  void _updateMyStatus() {
    final me = players.firstWhereOrNull((p) => p.sessionId == mySessionId.value);
    if (me != null) {
      myStatus.value = me.status;
    }
  }

  /// 검거 요청 받음 (도둑)
  void _handleArrestRequested(Map<String, dynamic> data) {
    final policeId = data['policeId'] as String?;
    final timeLimit = data['timeLimit'] as int? ?? 5;

    if (policeId == null) return;

    arrestRequestedBy.value = policeId;
    arrestTimeRemaining.value = timeLimit;

    // 카운트다운 시작
    _arrestTimer?.cancel();
    _arrestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (arrestTimeRemaining.value > 0) {
        arrestTimeRemaining.value--;
      } else {
        timer.cancel();
        // 시간 초과 시 자동으로 체포
        _socketService.respondArrest(policeId, false);
        arrestRequestedBy.value = null;
      }
    });

    // 검거 요청 다이얼로그 표시
    _showArrestDialog(policeId, timeLimit);
  }

  /// 검거 요청 다이얼로그
  void _showArrestDialog(String policeId, int timeLimit) {
    final policeName = players.firstWhereOrNull((p) => p.sessionId == policeId)?.nickname ?? '경찰';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.dangerRed),
            const SizedBox(width: 8),
            const Text('검거 요청!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$policeName님이 당신을 검거하려고 합니다!'),
            const SizedBox(height: 16),
            Obx(() => Text(
              '남은 시간: ${arrestTimeRemaining.value}초',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.dangerRed,
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _arrestTimer?.cancel();
              _socketService.respondArrest(policeId, false);
              arrestRequestedBy.value = null;
              Get.back();
            },
            child: const Text('거부 (도망가기)'),
          ),
          ElevatedButton(
            onPressed: () {
              _arrestTimer?.cancel();
              _socketService.respondArrest(policeId, true);
              arrestRequestedBy.value = null;
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.policeBlue,
            ),
            child: const Text('수락 (체포당함)'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// 플레이어 체포됨
  void _handlePlayerArrested(Map<String, dynamic> data) {
    final thiefId = data['thiefId'] as String?;
    final policeId = data['policeId'] as String?;

    if (thiefId == null || policeId == null) return;

    final thiefName = players.firstWhereOrNull((p) => p.sessionId == thiefId)?.nickname ?? '도둑';
    final policeName = players.firstWhereOrNull((p) => p.sessionId == policeId)?.nickname ?? '경찰';

    // 스낵바로 알림
    Get.snackbar(
      '🚨 검거 성공!',
      '$policeName님이 $thiefName님을 체포했습니다!',
      backgroundColor: AppTheme.policeBlue.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // 내가 체포당한 경우
    if (thiefId == mySessionId.value) {
      myStatus.value = PlayerStatus.dead;
      Get.snackbar(
        '💀 체포당했습니다',
        '감옥에서 동료의 탈옥을 기다리세요...',
        backgroundColor: AppTheme.dangerRed.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// 탈옥 시도
  void _handleJailbreakTriggered(Map<String, dynamic> data) {
    final thiefId = data['thiefId'] as String?;
    final duration = data['duration'] as int? ?? 3;

    if (thiefId == null) return;

    jailbreakInProgress.value = true;
    jailbreakTimeRemaining.value = duration;

    // 카운트다운
    _jailbreakTimer?.cancel();
    _jailbreakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (jailbreakTimeRemaining.value > 0) {
        jailbreakTimeRemaining.value--;
      } else {
        timer.cancel();
        jailbreakInProgress.value = false;
      }
    });

    final thiefName = players.firstWhereOrNull((p) => p.sessionId == thiefId)?.nickname ?? '도둑';

    Get.snackbar(
      '🚪 탈옥 시도!',
      '$thiefName님이 탈옥을 시도하고 있습니다! ($duration초)',
      backgroundColor: AppTheme.thiefRed.withOpacity(0.9),
      colorText: Colors.white,
      duration: Duration(seconds: duration),
    );
  }

  /// 플레이어 탈옥 성공
  void _handlePlayerFreed(Map<String, dynamic> data) {
    final freedThieves = (data['freedThieves'] as List?)
        ?.map((id) => id.toString())
        .toList() ?? [];

    if (freedThieves.isEmpty) return;

    jailbreakInProgress.value = false;
    _jailbreakTimer?.cancel();

    final names = freedThieves
        .map((id) => players.firstWhereOrNull((p) => p.sessionId == id)?.nickname ?? '도둑')
        .join(', ');

    Get.snackbar(
      '✅ 탈옥 성공!',
      '$names님이 탈옥에 성공했습니다!',
      backgroundColor: AppTheme.successGreen.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // 내가 탈옥한 경우
    if (freedThieves.contains(mySessionId.value)) {
      myStatus.value = PlayerStatus.alive;
    }
  }

  /// 게임 종료 처리
  void _handleGameEnded(Map<String, dynamic> data) {
    debugPrint('🏁 게임 종료: $data');

    // 위치 추적 중지
    _locationTimer?.cancel();

    final winner = GameWinner.fromString(data['winner'] ?? 'none');
    final finalState = GameStateModel.fromJson(data['finalState'] ?? {});

    // 결과 화면으로 이동
    Get.offAllNamed(Routes.RESULT, arguments: {
      'winner': winner,
      'finalState': finalState,
      'players': players,
    });
  }

  /// 위치 추적 시작
  void _startLocationTracking() {
    _locationService.startTracking();
    
    // 위치 변경 시 소켓 전송
    _locationService.onLocationChanged.listen((location) {
        if (location.latitude == null || location.longitude == null) return;
        
        _lastLat = location.latitude!;
        _lastLng = location.longitude!;
        
        // 5초마다가 아니라 변경될 때마다 보내거나, throttling 필요
        // 여기서는 간단히 매번 보냄 (최적화 필요)
        _socketService.updateLocation(
          _lastLat!,
          _lastLng!,
          0.0, // distance (계산 필요)
          0,   // steps (Pedometer 필요)
        );
    });
    
    // Geofence 이벤트 구독
    _geofenceService.onGeofenceEvent.listen((event) {
        final type = event['event'];
        // final id = event['id'];
        
        if (type == 'exit') {
            _socketService.notifyBoundaryExit();
            Get.snackbar('경고', '작전 구역을 이탈했습니다!', backgroundColor: Colors.red, colorText: Colors.white);
        } else if (type == 'enter') {
            _socketService.notifyBoundaryEnter();
            Get.snackbar('알림', '작전 구역으로 복귀했습니다.', backgroundColor: Colors.green, colorText: Colors.white);
        }
    });
  }

  /// 검거 요청 (경찰이 도둑을 검거)
  Future<void> requestArrest(String thiefId) async {
    if (myTeam.value != TeamType.police) {
      Get.snackbar('오류', '경찰만 검거할 수 있습니다.');
      return;
    }

    if (myStatus.value != PlayerStatus.alive) {
      Get.snackbar('오류', '게임 중일 때만 검거할 수 있습니다.');
      return;
    }

    _socketService.requestArrest(thiefId);

    Get.snackbar(
      '검거 요청',
      '검거 요청을 보냈습니다. 응답을 기다리는 중...',
      duration: const Duration(seconds: 2),
    );
  }

  /// 탈옥 시도 (도둑이 감옥에서 탈옥)
  Future<void> triggerJailbreak() async {
    if (myTeam.value != TeamType.thief) {
      Get.snackbar('오류', '도둑만 탈옥할 수 있습니다.');
      return;
    }

    if (myStatus.value != PlayerStatus.alive) {
      Get.snackbar('오류', '살아있는 도둑만 탈옥할 수 있습니다.');
      return;
    }

    if (_lastLat == null || _lastLng == null) {
      Get.snackbar('오류', '위치 정보를 가져올 수 없습니다.');
      return;
    }

    // 확인 다이얼로그
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('탈옥 시도'),
        content: const Text('탈옥을 시도하시겠습니까?\n3초간 감옥 근처에 있어야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.thiefRed,
            ),
            child: const Text('탈옥 시도'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 서버로 탈옥 요청 (위치는 서버에서 자동 확인)
    _socketService.triggerJailbreak();
  }

  /// 게임 나가기
  Future<void> leaveGame() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('게임 나가기'),
        content: const Text('정말 게임을 나가시겠습니까?\n게임 진행 중 나가면 팀에 불이익이 있을 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 위치 추적 중지
    _locationTimer?.cancel();

    // Socket 연결 해제
    _socketService.disconnect();

    // 로비로 이동
    Get.offAllNamed(Routes.LOBBY);
  }

  // Getters
  bool get isPolice => myTeam.value == TeamType.police;
  bool get isThief => myTeam.value == TeamType.thief;
  bool get isAlive => myStatus.value == PlayerStatus.alive;
  bool get isDead => myStatus.value == PlayerStatus.dead;

  PlayerModel? get me => players.firstWhereOrNull((p) => p.sessionId == mySessionId.value);

  List<PlayerModel> get policePlayers => players.where((p) => p.isPolice).toList();
  List<PlayerModel> get thiefPlayers => players.where((p) => p.isThief).toList();
  List<PlayerModel> get aliveThieves => thiefPlayers.where((p) => p.isAlive).toList();
  List<PlayerModel> get deadThieves => thiefPlayers.where((p) => p.isDead).toList();
}
