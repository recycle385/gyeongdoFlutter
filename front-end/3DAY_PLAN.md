# 🚀 3일 완성 계획 - 당근 술래잡기 (MVVM 아키텍처)

> **목표**: MVVM 아키텍처 기반으로 3일 안에 MVP(Minimum Viable Product) 완성

---

## 📐 MVVM 아키텍처 설계

```
lib/
├── main.dart                                # 앱 진입점
├── app/
│   ├── routes.dart                          # GetX 라우팅
│   ├── bindings.dart                        # 의존성 주입
│   ├── theme.dart                           # 앱 테마 (색상, 스타일 통일)
│   └── constants.dart                       # 상수 정의
│
├── models/                                  # [Model] 데이터 모델
│   ├── room_model.dart                      # 방 정보
│   ├── player_model.dart                    # 플레이어 정보
│   ├── game_state_model.dart                # 게임 상태
│   ├── location_model.dart                  # 위치 정보
│   └── polygon_model.dart                   # 폴리곤 데이터
│
├── services/                                # [Model] 비즈니스 로직 / 외부 API
│   ├── socket_service.dart                  # Socket.io 통신
│   ├── geofence_service.dart                # Geofencing (Method Channel)
│   ├── location_service.dart                # GPS 위치
│   ├── storage_service.dart                 # SharedPreferences
│   ├── sound_service.dart                   # TTS/오디오
│   └── api_service.dart                     # REST API 통신
│
├── view_models/                             # [ViewModel] GetX Controllers
│   ├── auth_controller.dart                 # 세션/닉네임 관리
│   ├── room_controller.dart                 # 방 생성/참여/OTP
│   ├── map_editor_controller.dart           # 지도 편집 (리팩토링)
│   ├── waiting_room_controller.dart         # 대기실 + 역할 배정
│   ├── game_controller.dart                 # 게임 진행 (경찰/도둑 공통)
│   └── result_controller.dart               # 결과 화면
│
├── views/                                   # [View] UI 화면
│   ├── auth/
│   │   └── nickname_view.dart               # 닉네임 설정
│   ├── lobby/
│   │   ├── lobby_view.dart                  # 방 만들기/참여 선택
│   │   ├── create_room_view.dart            # 방 생성 (지도 설정)
│   │   └── join_room_view.dart              # OTP 입력
│   ├── waiting/
│   │   └── waiting_room_view.dart           # 대기실 (역할 배정)
│   ├── game/
│   │   ├── police_game_view.dart            # 경찰 전용 화면
│   │   ├── thief_game_view.dart             # 도둑 전용 화면
│   │   └── widgets/
│   │       ├── player_list_card.dart        # 참가자 카드
│   │       ├── arrest_dialog.dart           # 검거 요청 다이얼로그
│   │       ├── boundary_warning.dart        # 영역 이탈 경고
│   │       └── jailbreak_button.dart        # 탈옥 버튼
│   ├── result/
│   │   └── result_view.dart                 # 결과 화면
│   └── common/
│       ├── map_drawing_painter.dart         # 지도 그리기 (기존)
│       ├── map_warning_dialog.dart          # 지도 경고 (기존)
│       ├── custom_button.dart               # 공통 버튼
│       ├── otp_display.dart                 # OTP 표시 위젯
│       └── loading_overlay.dart             # 로딩 화면
│
└── utils/
    ├── map_geometry_utils.dart              # 기하학 계산 (기존)
    └── validators.dart                       # 입력 검증

ios/Runner/
├── AppDelegate.swift                         # Method Channel 연결
├── GeofenceManager.swift                     # Core Location 래퍼
└── Info.plist                                # 위치 권한 설명

android/app/src/main/kotlin/com/carrot/hideseek/
├── MainActivity.kt                           # Method Channel 연결
├── GeofenceManager.kt                        # GeofencingClient 래퍼
└── GeofenceBroadcastReceiver.kt              # Geofence 이벤트 수신

server/                                       # Node.js 백엔드
├── index.js                                  # Express + Socket.io
├── package.json
├── .env
└── Dockerfile
```

---

## 📅 Day 1 (8시간): 아키텍처 리팩토링 + 기본 플로우

### 오전 (4시간): MVVM 리팩토링 + 테마 시스템

#### 1.1 프로젝트 구조 재정비 (30분)
```bash
# 폴더 생성
lib/
├── app/
├── models/
├── services/
├── view_models/
└── views/
    ├── auth/
    ├── lobby/
    ├── waiting/
    ├── game/widgets/
    ├── result/
    └── common/
```

#### 1.2 테마 시스템 구축 (30분)
**파일**: `lib/app/theme.dart`
```dart
class AppTheme {
  static const carrotOrange = Color(0xFFFF6F0F);
  static const policeBlue = Color(0xFF1E88E5);
  static const thiefRed = Color(0xFFE53935);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: carrotOrange),
    // 버튼, 카드 등 공통 스타일 정의
  );
}
```

#### 1.3 Models 작성 (1시간)
- `room_model.dart`: 방 정보 (id, hostId, status, playArea, jailLocation, duration)
- `player_model.dart`: 플레이어 정보 (sessionId, nickname, role, team, status, stats)
- `game_state_model.dart`: 게임 상태 (remainingTime, aliveThieves, deadThieves)
- `polygon_model.dart`: 폴리곤 데이터

#### 1.4 Storage Service (30분)
**파일**: `lib/services/storage_service.dart`
```dart
class StorageService extends GetxService {
  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  String? get sessionId => _prefs.getString('sessionId');
  String? get nickname => _prefs.getString('nickname');

  Future<void> saveSession(String id, String name) async {
    await _prefs.setString('sessionId', id);
    await _prefs.setString('nickname', name);
  }
}
```

#### 1.5 API Service (1시간)
**파일**: `lib/services/api_service.dart`
```dart
class ApiService extends GetxService {
  final String baseUrl = 'http://localhost:3000/api'; // 나중에 .env로 이동

  Future<Map<String, dynamic>> createSession(String nickname);
  Future<Map<String, dynamic>> createRoom(/*...*/);
  Future<Map<String, dynamic>> joinRoom(String otpCode, String sessionId);
  Future<String> refreshOTP(String roomId);
}
```

### 오후 (4시간): 인증 + 로비 화면

#### 1.6 닉네임 설정 화면 (1시간)
**ViewModel**: `lib/view_models/auth_controller.dart`
```dart
class AuthController extends GetxController {
  final StorageService _storage = Get.find();
  final ApiService _api = Get.find();

  final nicknameController = TextEditingController();
  final isLoading = false.obs;

  Future<void> setNickname() async {
    // API 호출 → Storage 저장 → 로비로 이동
  }
}
```

**View**: `lib/views/auth/nickname_view.dart`
- TextField + "시작하기" 버튼
- GetX binding 연결

#### 1.7 로비 화면 (30분)
**View**: `lib/views/lobby/lobby_view.dart`
- "방 만들기" 버튼 → 지도 설정으로 이동
- "참여하기" 버튼 → OTP 입력 화면으로 이동

#### 1.8 지도 편집 화면 리팩토링 (1.5시간)
**ViewModel**: `lib/view_models/map_editor_controller.dart`
- 기존 `map_editor_provider.dart`를 GetX Controller로 변환
- Provider → GetX 상태 관리 변경
- `Rx` 변수 사용 (`Obs`)

**View**: `lib/views/lobby/create_room_view.dart`
- 기존 `map_test_view.dart` 코드 이동
- GetX binding 연결
- 완료 시 서버에 방 생성 API 호출

#### 1.9 OTP 참여 화면 (1시간)
**ViewModel**: `lib/view_models/room_controller.dart`
```dart
class RoomController extends GetxController {
  final otpCode = ''.obs;

  Future<void> joinRoom() async {
    // API 호출 → 대기실로 이동
  }
}
```

**View**: `lib/views/lobby/join_room_view.dart`
- 4자리 OTP 입력 필드
- "참여하기" 버튼

---

## 📅 Day 2 (8시간): Socket 통신 + 게임 로직 + 대기실

### 오전 (4시간): Socket.io + 대기실

#### 2.1 Socket Service (1.5시간)
**파일**: `lib/services/socket_service.dart`
```dart
class SocketService extends GetxService {
  late IO.Socket socket;

  Future<SocketService> init() async {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) => print('Socket 연결됨'));

    // 이벤트 리스너 등록
    socket.on('players:updated', _onPlayersUpdated);
    socket.on('role:assigned', _onRoleAssigned);
    socket.on('game:started', _onGameStarted);
    // ... 나머지 이벤트들

    return this;
  }

  void joinRoom(String roomId, String sessionId) {
    socket.emit('room:join', {'roomId': roomId, 'sessionId': sessionId});
  }

  void assignRole(String targetSessionId, String team) {
    socket.emit('role:assign', {'targetSessionId': targetSessionId, 'team': team});
  }

  // 이벤트 핸들러들...
}
```

#### 2.2 대기실 Controller (1시간)
**ViewModel**: `lib/view_models/waiting_room_controller.dart`
```dart
class WaitingRoomController extends GetxController {
  final SocketService _socket = Get.find();

  final players = <PlayerModel>[].obs;
  final roomInfo = Rx<RoomModel?>(null);
  final isHost = false.obs;

  @override
  void onInit() {
    super.onInit();
    _socket.socket.on('players:updated', _updatePlayers);
  }

  void toggleRole(String sessionId, String currentTeam) {
    final newTeam = currentTeam == 'police' ? 'thief' : 'police';
    _socket.assignRole(sessionId, newTeam);
  }

  Future<void> startGame() async {
    _socket.socket.emit('game:start');
  }
}
```

#### 2.3 대기실 View (1.5시간)
**View**: `lib/views/waiting/waiting_room_view.dart`

**방장 화면:**
- OTP 코드 표시 (30초마다 갱신)
- 참가자 목록 (역할 배정 토글 버튼)
- "게임 시작" 버튼

**참여자 화면:**
- 참가자 목록 (읽기 전용)
- 본인 역할 하이라이트

### 오후 (4시간): 게임 진행 화면

#### 2.4 Game Controller (2시간)
**ViewModel**: `lib/view_models/game_controller.dart`
```dart
class GameController extends GetxController {
  final SocketService _socket = Get.find();

  final players = <PlayerModel>[].obs;
  final gameState = Rx<GameStateModel?>(null);
  final myRole = ''.obs; // 'police' or 'thief'

  @override
  void onInit() {
    super.onInit();
    _socket.socket.on('player:arrested', _onPlayerArrested);
    _socket.socket.on('jailbreak:success', _onJailbreakSuccess);
    _socket.socket.on('game:tick', _onGameTick);
    _socket.socket.on('game:ended', _onGameEnded);
  }

  void requestArrest(String targetSessionId) {
    _socket.socket.emit('arrest:request', {'targetSessionId': targetSessionId});
  }

  void respondArrest(String requestId, bool accepted) {
    _socket.socket.emit('arrest:respond', {'requestId': requestId, 'accepted': accepted});
  }

  void triggerJailbreak() {
    _socket.socket.emit('jailbreak:trigger');
  }

  void notifyBoundaryExit() {
    _socket.socket.emit('boundary:exit');
  }

  void notifyBoundaryEnter() {
    _socket.socket.emit('boundary:enter');
  }
}
```

#### 2.5 경찰 화면 (1시간)
**View**: `lib/views/game/police_game_view.dart`

**구성:**
- 타이머 (remainingTime)
- 생존자/체포자 카운트
- 참가자 목록 (전체 보임)
  - 도둑 옆에 [검거 요청] 버튼
- 운동량 통계
- [전체 방송(TTS)] 버튼

#### 2.6 도둑 화면 (1시간)
**View**: `lib/views/game/thief_game_view.dart`

**구성:**
- 타이머
- 생존자/체포자 카운트
- 참가자 목록 (도둑만 보임)
- 운동량 통계
- 감옥까지 거리
- [탈옥 시키기] 버튼 (15m 이내 활성화)

---

## 📅 Day 3 (8시간): 네이티브 Geofencing + 백엔드 + 최종 통합

### 오전 (4시간): 백엔드 개발

#### 3.1 Express.js 서버 (2시간)
**파일**: `server/index.js`

**구현:**
- REST API 엔드포인트 (세션, 방 생성, OTP 검증)
- Socket.io 이벤트 핸들러
- Redis 연결 및 데이터 구조
- 게임 타이머 로직
- 체포/탈옥 로직
- MVP 계산 로직

#### 3.2 Redis 데이터 구조 (30분)
- 방 정보 (room:{roomId})
- OTP (room:{roomId}:otp)
- 플레이어 (room:{roomId}:players:{sessionId})
- 게임 상태 (room:{roomId}:state)
- 세션 (session:{sessionId})

#### 3.3 서버 테스트 (30분)
- Postman으로 REST API 테스트
- Socket.io 클라이언트로 이벤트 테스트

#### 3.4 Docker 설정 (1시간)
```dockerfile
# server/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  server:
    build: ./server
    ports:
      - "3000:3000"
    environment:
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis
```

### 오후 (4시간): 네이티브 Geofencing + 결과 화면 + 최종 통합

#### 3.5 iOS Geofencing (1시간)
**파일**: `ios/Runner/GeofenceManager.swift`
- Core Location 래퍼
- Method Channel 연결

**파일**: `ios/Runner/AppDelegate.swift`
- Method Channel 핸들러

**파일**: `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>게임 구역 감지를 위해 위치 권한이 필요합니다.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>백그라운드에서 게임 구역 이탈을 감지합니다.</string>
```

#### 3.6 Android Geofencing (1시간)
**파일**: `android/app/src/main/kotlin/.../GeofenceManager.kt`
- GeofencingClient 래퍼

**파일**: `android/app/src/main/kotlin/.../GeofenceBroadcastReceiver.kt`
- Geofence 이벤트 수신

**파일**: `android/app/src/main/kotlin/.../MainActivity.kt`
- Method Channel 핸들러

**파일**: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

#### 3.7 Geofence Service (Flutter) (30분)
**파일**: `lib/services/geofence_service.dart`
- Method Channel 연결
- Geofence 등록/해제
- 이벤트 스트림

#### 3.8 결과 화면 (1시간)
**ViewModel**: `lib/view_models/result_controller.dart`
```dart
class ResultController extends GetxController {
  final winner = ''.obs;
  final mvp = Rx<Map<String, PlayerModel>?>({});
  final myStats = Rx<PlayerModel?>(null);

  void navigateToLobby() {
    Get.offAllNamed(Routes.LOBBY);
  }
}
```

**View**: `lib/views/result/result_view.dart`
- 승리 팀 표시
- MVP (검거왕, 생존왕, 구출왕)
- 나의 기록 (거리, 칼로리, 걸음 수)
- [다시하기] / [나가기] 버튼

#### 3.9 최종 통합 테스트 (30분)
1. 닉네임 설정 → 로비
2. 방 생성 (지도 그리기)
3. OTP로 참여 (다른 기기 시뮬레이션)
4. 역할 배정
5. 게임 시작
6. 검거/탈옥 테스트
7. 게임 종료 및 결과 확인

---

## 🔧 필수 패키지 추가

**pubspec.yaml 업데이트:**
```yaml
dependencies:
  # 기존
  flutter:
    sdk: flutter
  flutter_naver_map: ^1.4.4
  location: ^5.0.0
  latlong2: ^0.9.1
  flutter_dotenv: ^5.1.0
  cupertino_icons: ^1.0.8
  get: ^4.7.3

  # 추가
  socket_io_client: ^2.0.3+1           # Socket.io
  shared_preferences: ^2.2.0            # 로컬 저장소
  flutter_local_notifications: ^16.3.2  # 알림
  permission_handler: ^11.3.0           # 권한
  flutter_tts: ^3.8.5                   # TTS
  audioplayers: ^5.2.1                  # 오디오
  vibration: ^1.8.4                     # 진동
  pedometer: ^4.0.2                     # 만보기
  http: ^1.2.0                          # HTTP 통신
```

---

## ⚙️ 서버 패키지 (server/package.json)

```json
{
  "name": "carrot-hideseek-server",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.7.0",
    "cors": "^2.8.5",
    "@turf/turf": "^7.0.0",
    "ioredis": "^5.3.0",
    "uuid": "^9.0.0",
    "dotenv": "^16.0.0"
  }
}
```

---

## 🎯 3일 완성을 위한 핵심 전략

### 우선순위 설정
1. **필수 기능 (MVP)**: 방 생성/참여, 대기실, 게임 진행, 검거/탈옥
2. **후순위**: TTS, 채팅, 만보기, 칼로리 계산
3. **생략 가능**: 정교한 UI 애니메이션, 고급 에러 처리

### 시간 분배
- **Day 1**: 아키텍처 + 기본 플로우 (60%)
- **Day 2**: 실시간 통신 + 게임 로직 (80%)
- **Day 3**: 네이티브 + 백엔드 + 통합 (100%)

### 병렬 작업
- 백엔드는 Day 2 오전부터 시작 가능 (API 스펙만 맞추면 됨)
- iOS/Android 네이티브는 Day 2 오후부터 시작 가능

### 테스트 전략
- 단위 테스트 생략 (시간 부족)
- 통합 테스트에 집중
- 최소 2대 기기로 실제 플레이 테스트

---

## 📝 체크리스트

### Day 1
- [ ] MVVM 폴더 구조 생성
- [ ] 테마 시스템 (theme.dart)
- [ ] Models 작성 (4개)
- [ ] Storage Service
- [ ] API Service
- [ ] 닉네임 화면
- [ ] 로비 화면
- [ ] 지도 편집 리팩토링 (Provider → GetX)
- [ ] OTP 참여 화면

### Day 2
- [ ] Socket Service
- [ ] 대기실 Controller
- [ ] 대기실 View (방장/참여자)
- [ ] Game Controller
- [ ] 경찰 화면
- [ ] 도둑 화면
- [ ] 검거 요청 다이얼로그
- [ ] 영역 이탈 경고

### Day 3
- [ ] Express.js 서버 (REST API)
- [ ] Socket.io 이벤트 핸들러
- [ ] Redis 데이터 구조
- [ ] Docker 설정
- [ ] iOS Geofencing
- [ ] Android Geofencing
- [ ] Geofence Service (Flutter)
- [ ] 결과 화면
- [ ] 최종 통합 테스트

---

## 🚨 리스크 관리

### 예상되는 문제
1. **네이티브 Geofencing 디버깅 시간**
   - 해결: 시뮬레이터 대신 실제 기기 사용
   - 대안: 간단한 GPS 거리 체크로 대체

2. **Socket.io 실시간 동기화 이슈**
   - 해결: 서버에서 강제 동기화 이벤트 전송
   - 대안: 클라이언트 폴링 추가

3. **Redis 설치/설정**
   - 해결: Docker Compose 사용
   - 대안: 메모리 기반 임시 저장소

### 타임 버퍼
- 각 Day마다 1-2시간 버퍼 확보
- Day 3 오후 2시간은 예비 시간으로 활용

---

## ✅ 성공 기준

**최소 요구사항 (MVP):**
- ✅ 방 생성 및 OTP 참여
- ✅ 역할 배정 (방장)
- ✅ 게임 진행 (타이머, 플레이어 상태)
- ✅ 검거 시스템
- ✅ 탈옥 시스템
- ✅ 영역 이탈 감지 (Geofence)
- ✅ 결과 화면

**추가 목표 (시간 여유 시):**
- TTS 음성 안내
- 만보기 연동
- 도둑 간 채팅
- 정교한 UI/UX

---

이 계획은 타이트하지만 실현 가능합니다. MVVM 아키텍처를 유지하면서 GetX의 강력한 상태 관리와 의존성 주입을 활용하면 3일 안에 MVP를 완성할 수 있습니다.
