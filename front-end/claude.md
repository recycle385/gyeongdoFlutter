# 🥕 당근 술래잡기 (Carrot Hide & Seek)

> 오프라인 술래잡기를 보조하는 디지털 심판 & 스코어보드 앱

---

## 📋 프로젝트 개요

### 핵심 컨셉
- **목적**: 실시간 위치 공유 없이, 게임 룰 판정(영역 이탈, 체포, 탈옥)과 결과 정산(운동량)에 집중
- **타겟**: 당근마켓 모임 등 일회성으로 모여 술래잡기를 하는 그룹
- **특징**: 배터리/데이터 이슈 최소화 (OS 네이티브 Geofencing 기반)

### 팀 구성
- **경찰(Police/Runner)**: 도둑을 잡는 역할
- **도둑(Thief/Hider)**: 도망 다니며 생존하는 역할
- **방장(Host)**: 게임 설정 및 역할 배정 권한 보유

---

## 🛠️ 기술 스택

### Frontend (Flutter)
```yaml
dependencies:
  flutter: sdk
  
  # 지도
  flutter_naver_map: ^1.0.2
  
  # GPS (포그라운드 전용)
  geolocator: ^11.0.0
  
  # 알림
  flutter_local_notifications: ^16.3.2
  permission_handler: ^11.3.0
  
  # 실시간 통신
  socket_io_client: ^2.0.3+1
  
  # 상태관리
  get: ^4.6.6
  
  # 사운드 & 피드백
  flutter_tts: ^3.8.5
  audioplayers: ^5.2.1
  vibration: ^1.8.4
  
  # 유틸리티
  pedometer: ^4.0.2              # 만보기
  shared_preferences: ^2.2.0     # 세션 저장
  
  # 공간 연산 (클라이언트 보조)
  turf: ^0.0.8
```

### 네이티브 Geofencing (Method Channel)
```
iOS: Core Location - CLLocationManager.startMonitoring(for: CLCircularRegion)
Android: Google Play Services - GeofencingClient

→ Flutter에서 Method Channel로 호출
→ 완전 무료 + OS 레벨 배터리 최적화
```

### Backend (Node.js + Express)
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.7.0",
    "cors": "^2.8.5",
    "@turf/turf": "^7.0.0",
    "ioredis": "^5.3.0",
    "uuid": "^9.0.0"
  }
}
```

### Infrastructure
- **Database**: Redis Only (일회성 게임, TTL 자동 삭제)
- **Map API**: NAVER Maps API (월 1,000만 건 무료)
- **Server**: AWS EC2 t3.small + ElastiCache Redis
- **예상 비용**: ~$27/월

---

## 👥 사용자 플로우

### 방장 (Host) 플로우
```
앱 실행 → 닉네임 설정 → 방 생성 → 지도에서 구역/감옥 설정 
→ OTP 코드 공유 → 참여자 대기 → [역할 직접 배정] → 게임 시작 
→ 현황판 확인 → 종료 후 결과 확인
```

### 참여자 (Player) 플로우
```
앱 실행 → 닉네임 설정 → OTP 코드 입력 → 대기실 입장 
→ [방장이 역할 배정] → 게임 대기 → 플레이 → 결과 확인
```

---

## 📱 화면 구성

### 1. 로비 화면들

#### 1-1. 닉네임 설정 (`/nickname`)
- 닉네임 입력 필드
- 서버에서 세션 ID(UUID) 발급받아 로컬 저장
- "방 만들기" / "참여하기" 버튼

#### 1-2. 방 생성 - 지도 설정 (`/host/map-setup`)
- 네이버 지도 전체 화면
- 터치로 다각형(Polygon) 꼭짓점 찍어 활동 구역 설정
- 핀(Marker)으로 감옥 위치 설정 (기본 반경 15m)
- 게임 시간 설정 (기본 30분)
- "다음" 버튼 → 대기실로 이동

#### 1-3. 방 참여 (`/join`)
- 4자리 OTP 코드 입력 필드
- 코드 검증 실패 시 에러 메시지
- 성공 시 대기실로 이동

#### 1-4. 대기실 (`/waiting-room`)
**방장 화면:**
- OTP 코드 표시 (30초마다 자동 갱신)
- 참여자 목록 (닉네임 + 미배정 상태)
- **역할 배정 UI**: 각 참여자 옆에 [경찰👮]/[도둑🦹] 토글 버튼
- "게임 시작" 버튼 (모든 참여자 역할 배정 완료 시 활성화)

**참여자 화면:**
- "대기 중..." 상태 표시
- 참여자 목록 (역할 배정되면 표시)
- 본인 역할 배정되면 하이라이트

---

### 2. 게임 화면 (역할별 분리)

> ⚠️ **중요**: 경찰/도둑 화면은 완전히 다른 UI

#### 2-1. 경찰 화면 (`/game/police`)

```
┌─────────────────────────────────────┐
│  [로고]  당근술래잡기    ● 실시간    │
├─────────────────────────────────────┤
│                                     │
│            ⏱️ 14:59                 │
│             남은 시간                │
│                                     │
├──────────────────┬──────────────────┤
│   생존자(Runner) │   체포자(Jail)    │
│       🟢 8       │      🔴 2        │
├──────────────────┴──────────────────┤
│  📋 참가자 목록                      │
├─────────────────────────────────────┤
│  🟢 나  홍길동 (나)                  │
│        🏃 생존 (경찰)                │
├─────────────────────────────────────┤
│  🟢    김철수         [🚨 검거 요청] │ ← 도둑만 검거 버튼
│        🏃 120m 이동                  │
├─────────────────────────────────────┤
│  🔴    이영희                        │
│        💀 체포됨                     │
├─────────────────────────────────────┤
│                                     │
│  📊 12.4 km  |  1.2 kcal  |  85 걸음 │
│                                     │
├─────────────────────────────────────┤
│       [📢 전체 방송 (TTS) 시작]      │
└─────────────────────────────────────┘
```

**경찰 전용 기능:**
- 참가자 리스트에서 도둑 옆에 [검거 요청] 버튼
- 전체 방송(TTS) 버튼

#### 2-2. 도둑 화면 (`/game/thief`)

```
┌─────────────────────────────────────┐
│  [로고]  당근술래잡기    ● 실시간    │
├─────────────────────────────────────┤
│                                     │
│            ⏱️ 14:59                 │
│             남은 시간                │
│                                     │
├──────────────────┬──────────────────┤
│   생존자(Runner) │   체포자(Jail)    │
│       🟢 8       │      🔴 2        │
├──────────────────┴──────────────────┤
│  📋 참가자 목록 (도둑만 표시)        │
├─────────────────────────────────────┤
│  🟢 나  박도둑 (나)                  │
│        🏃 생존                       │
├─────────────────────────────────────┤
│  🟢    김도둑                        │
│        🏃 생존                       │
├─────────────────────────────────────┤
│  🔴    이도둑         [💬 채팅]      │
│        💀 감옥 (구출 대기)           │
├─────────────────────────────────────┤
│                                     │
│  📊 8.2 km  |  0.8 kcal  |  52 걸음  │
│                                     │
├─────────────────────────────────────┤
│  ⚠️ 감옥까지 150m                   │
│  [🚨 탈옥 시키기] (비활성)           │ ← 15m 이내 시 활성화
└─────────────────────────────────────┘
```

**도둑 전용 기능:**
- 경찰 위치/목록 **안 보임** (도둑끼리만 보임)
- 감옥까지 거리 표시
- [탈옥 시키기] 버튼: 감옥 반경 15m 진입 시 활성화
- 도둑 간 1:1 채팅

#### 2-3. 영역 이탈 경고 (공통)

```
┌─────────────────────────────────────┐
│  ⚠️ 경고!                           │
│                                     │
│  작전 구역을 벗어났습니다!           │
│                                     │
│  ⏱️ 복귀까지 남은 시간: 00:45       │
│                                     │
│  1분 내로 복귀하지 않으면            │
│  자동으로 체포됩니다!                │
└─────────────────────────────────────┘
```

#### 2-4. 체포 요청 팝업 (도둑에게 표시)

```
┌─────────────────────────────────────┐
│  👮 검거 요청!                       │
│                                     │
│  '홍길동' 경찰이                     │
│  당신을 잡았습니다!                  │
│                                     │
│  ┌─────────────┐ ┌─────────────┐   │
│  │  ✅ 인정    │ │  ❌ 거절    │   │
│  │  (체포됨)   │ │  (실수 시)  │   │
│  └─────────────┘ └─────────────┘   │
│                                     │
│  ⏱️ 10초 내 응답하세요              │
└─────────────────────────────────────┘
```

#### 2-5. 탈옥 성공 알림 (전체)

```
┌─────────────────────────────────────┐
│  🚨 탈옥 성공!                       │
│                                     │
│  '구출왕'님이 감옥을 열었습니다!     │
│                                     │
│  🔊 [사이렌 + TTS 자동 재생]        │
│  "탈옥 성공! 전원 흩어지세요!"       │
│                                     │
│  부활한 도둑: 3명                    │
└─────────────────────────────────────┘
```

---

### 3. 결과 화면 (`/result`)

```
┌─────────────────────────────────────┐
│           🎉 게임 종료!              │
├─────────────────────────────────────┤
│                                     │
│         🦹 도둑 승리!                │
│      (생존자 3명으로 종료)           │
│                                     │
├─────────────────────────────────────┤
│  🏆 MVP                              │
├─────────────────────────────────────┤
│  👮 검거왕: 홍길동 (5명 검거)        │
│  🦹 생존왕: 김철수 (끝까지 생존)     │
│  🦸 구출왕: 이영희 (3회 탈옥)        │
├─────────────────────────────────────┤
│  📊 나의 기록                        │
├─────────────────────────────────────┤
│  🏃 이동 거리    │    12.4 km        │
│  🔥 소모 칼로리  │    156 kcal       │
│  👟 걸음 수      │    8,542 걸음     │
├─────────────────────────────────────┤
│                                     │
│  [🔄 다시하기]    [🚪 나가기]        │
└─────────────────────────────────────┘
```

---

## 📍 네이티브 Geofencing 구현

### 개요

```
┌─────────────────────────────────────────────────────┐
│  Flutter (Dart)                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  GeofenceService (Method Channel)             │  │
│  │  - registerPlayAreaGeofence()                 │  │
│  │  - registerJailGeofence()                     │  │
│  │  - onGeofenceEvent (콜백)                     │  │
│  └───────────────────┬───────────────────────────┘  │
└──────────────────────┼──────────────────────────────┘
                       │ Method Channel
       ┌───────────────┴───────────────┐
       ▼                               ▼
┌─────────────────────┐    ┌─────────────────────┐
│  iOS (Swift)        │    │  Android (Kotlin)   │
│  Core Location      │    │  GeofencingClient   │
│  CLLocationManager  │    │  Google Play Services│
└─────────────────────┘    └─────────────────────┘
```

### iOS 네이티브 코드 (Swift)

```swift
// ios/Runner/GeofenceManager.swift

import CoreLocation
import Flutter

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    static let shared = GeofenceManager()
    
    private let locationManager = CLLocationManager()
    var eventSink: FlutterEventSink?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    // Geofence 등록 (원형 영역)
    func registerGeofence(id: String, lat: Double, lng: Double, radius: Double) {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            radius: radius,
            identifier: id
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    // Geofence 해제
    func removeGeofence(id: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == id {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    // 모든 Geofence 해제
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        eventSink?(["event": "enter", "id": region.identifier])
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        eventSink?(["event": "exit", "id": region.identifier])
    }
}
```

```swift
// ios/Runner/AppDelegate.swift

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Method Channel
        let methodChannel = FlutterMethodChannel(
            name: "com.carrot.hideseek/geofence",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "register":
                let args = call.arguments as! [String: Any]
                GeofenceManager.shared.registerGeofence(
                    id: args["id"] as! String,
                    lat: args["lat"] as! Double,
                    lng: args["lng"] as! Double,
                    radius: args["radius"] as! Double
                )
                result(nil)
                
            case "remove":
                let id = call.arguments as! String
                GeofenceManager.shared.removeGeofence(id: id)
                result(nil)
                
            case "removeAll":
                GeofenceManager.shared.removeAllGeofences()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Event Channel
        let eventChannel = FlutterEventChannel(
            name: "com.carrot.hideseek/geofence_events",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(GeofenceStreamHandler())
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

class GeofenceStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        GeofenceManager.shared.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        GeofenceManager.shared.eventSink = nil
        return nil
    }
}
```

### Android 네이티브 코드 (Kotlin)

```kotlin
// android/app/src/main/kotlin/com/carrot/hideseek/GeofenceManager.kt

package com.carrot.hideseek

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.plugin.common.EventChannel

class GeofenceManager(private val context: Context) {
    
    private val geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }
    
    fun registerGeofence(id: String, lat: Double, lng: Double, radius: Float) {
        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lng, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(
                Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT
            )
            .build()
        
        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()
        
        geofencingClient.addGeofences(request, getGeofencePendingIntent())
    }
    
    fun removeGeofence(id: String) {
        geofencingClient.removeGeofences(listOf(id))
    }
    
    fun removeAllGeofences() {
        geofencingClient.removeGeofences(getGeofencePendingIntent())
    }
    
    private fun getGeofencePendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        return PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }
}
```

```kotlin
// android/app/src/main/kotlin/com/carrot/hideseek/GeofenceBroadcastReceiver.kt

package com.carrot.hideseek

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent) ?: return
        
        if (geofencingEvent.hasError()) return
        
        val transition = geofencingEvent.geofenceTransition
        val triggeringGeofences = geofencingEvent.triggeringGeofences ?: return
        
        triggeringGeofences.forEach { geofence ->
            val eventType = when (transition) {
                Geofence.GEOFENCE_TRANSITION_ENTER -> "enter"
                Geofence.GEOFENCE_TRANSITION_EXIT -> "exit"
                else -> return@forEach
            }
            
            GeofenceManager.eventSink?.success(
                mapOf("event" to eventType, "id" to geofence.requestId)
            )
        }
    }
}
```

```kotlin
// android/app/src/main/kotlin/com/carrot/hideseek/MainActivity.kt

package com.carrot.hideseek

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var geofenceManager: GeofenceManager
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        geofenceManager = GeofenceManager(this)
        
        // Method Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.carrot.hideseek/geofence"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "register" -> {
                    val args = call.arguments as Map<*, *>
                    geofenceManager.registerGeofence(
                        args["id"] as String,
                        args["lat"] as Double,
                        args["lng"] as Double,
                        (args["radius"] as Double).toFloat()
                    )
                    result.success(null)
                }
                "remove" -> {
                    geofenceManager.removeGeofence(call.arguments as String)
                    result.success(null)
                }
                "removeAll" -> {
                    geofenceManager.removeAllGeofences()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Event Channel
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.carrot.hideseek/geofence_events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                GeofenceManager.eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                GeofenceManager.eventSink = null
            }
        })
    }
}
```

### Flutter 서비스 (Dart)

```dart
// lib/services/geofence_service.dart

import 'package:flutter/services.dart';

class GeofenceService {
  static const _methodChannel = MethodChannel('com.carrot.hideseek/geofence');
  static const _eventChannel = EventChannel('com.carrot.hideseek/geofence_events');
  
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();
  
  Function(String event, String id)? onGeofenceEvent;
  
  void init() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final event = data['event'] as String;
      final id = data['id'] as String;
      onGeofenceEvent?.call(event, id);
    });
  }
  
  Future<void> registerPlayArea({
    required double centerLat,
    required double centerLng,
    required double radius,
  }) async {
    await _methodChannel.invokeMethod('register', {
      'id': 'play_area',
      'lat': centerLat,
      'lng': centerLng,
      'radius': radius,
    });
  }
  
  Future<void> registerJail({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    await _methodChannel.invokeMethod('register', {
      'id': 'jail',
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
  }
  
  Future<void> removeGeofence(String id) async {
    await _methodChannel.invokeMethod('remove', id);
  }
  
  Future<void> removeAll() async {
    await _methodChannel.invokeMethod('removeAll');
  }
}
```

---

## 🗄️ 데이터 구조 (Redis)

```redis
# 방 정보 (TTL: 2시간)
HSET room:{roomId}
    hostSessionId   "uuid-xxx"
    status          "waiting|playing|finished"
    playArea        '{"type":"Polygon","coordinates":[[[127.0,37.5],...]]}'
    jailLocation    '{"type":"Point","coordinates":[127.0,37.5]}'
    jailRadius      15
    duration        1800
    startedAt       1704067200

EXPIRE room:{roomId} 7200

# OTP (TTL: 30초)
SET room:{roomId}:otp "1234" EX 30

# 플레이어 (TTL: 2시간)
HSET room:{roomId}:players:{sessionId}
    nickname      "홍길동"
    role          "host|player"
    team          "police|thief|unassigned"
    status        "alive|dead"
    arrestCount   0
    rescueCount   0

# 게임 상태
HSET room:{roomId}:state
    remainingTime   1200
    aliveThieves    5
    deadThieves     3

# 세션 (TTL: 2시간)
HSET session:{sessionId}
    nickname    "홍길동"
    roomId      "room-xxx"
```

---

## 📡 서버 코드 (Express.js + Socket.io)

```javascript
// server/index.js

const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const Redis = require('ioredis');
const crypto = require('crypto');
const turf = require('@turf/turf');

const app = express();
const server = createServer(app);
const io = new Server(server, { cors: { origin: '*' } });
const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

app.use(cors());
app.use(express.json());

// ==================== REST API ====================

// 세션 생성
app.post('/api/session', async (req, res) => {
  const { nickname } = req.body;
  const sessionId = crypto.randomUUID();
  
  await redis.hset(`session:${sessionId}`, { nickname, createdAt: Date.now() });
  await redis.expire(`session:${sessionId}`, 7200);
  
  res.json({ sessionId });
});

// 방 생성
app.post('/api/rooms', async (req, res) => {
  const { sessionId, playArea, jailLocation, jailRadius, duration } = req.body;
  const roomId = crypto.randomUUID();
  const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
  
  await redis.hset(`room:${roomId}`, {
    hostSessionId: sessionId,
    status: 'waiting',
    playArea: JSON.stringify(playArea),
    jailLocation: JSON.stringify(jailLocation),
    jailRadius,
    duration,
  });
  await redis.expire(`room:${roomId}`, 7200);
  await redis.setex(`room:${roomId}:otp`, 30, otpCode);
  
  const nickname = await redis.hget(`session:${sessionId}`, 'nickname');
  await redis.hset(`room:${roomId}:players:${sessionId}`, {
    nickname,
    role: 'host',
    team: 'unassigned',
    status: 'alive',
    arrestCount: 0,
    rescueCount: 0,
  });
  
  res.json({ roomId, otpCode });
});

// OTP 검증 및 방 참여
app.post('/api/rooms/join', async (req, res) => {
  const { otpCode, sessionId } = req.body;
  
  const keys = await redis.keys('room:*:otp');
  let roomId = null;
  
  for (const key of keys) {
    const storedOtp = await redis.get(key);
    if (storedOtp === otpCode) {
      roomId = key.split(':')[1];
      break;
    }
  }
  
  if (!roomId) {
    return res.status(400).json({ error: '유효하지 않은 코드입니다' });
  }
  
  const nickname = await redis.hget(`session:${sessionId}`, 'nickname');
  await redis.hset(`room:${roomId}:players:${sessionId}`, {
    nickname,
    role: 'player',
    team: 'unassigned',
    status: 'alive',
    arrestCount: 0,
    rescueCount: 0,
  });
  
  res.json({ roomId });
});

// OTP 갱신
app.post('/api/rooms/:roomId/otp/refresh', async (req, res) => {
  const { roomId } = req.params;
  const newCode = Math.floor(1000 + Math.random() * 9000).toString();
  await redis.setex(`room:${roomId}:otp`, 30, newCode);
  res.json({ otpCode: newCode });
});

// ==================== Socket.io ====================

const boundaryTimers = new Map();
const gameTimers = new Map();

io.on('connection', (socket) => {
  console.log('연결:', socket.id);
  
  // 방 입장
  socket.on('room:join', async ({ roomId, sessionId }) => {
    socket.join(roomId);
    socket.join(sessionId);
    socket.data = { roomId, sessionId };
    
    io.to(roomId).emit('players:updated', await getPlayerList(roomId));
  });
  
  // 역할 배정 (방장)
  socket.on('role:assign', async ({ targetSessionId, team }) => {
    const { roomId, sessionId } = socket.data;
    const hostId = await redis.hget(`room:${roomId}`, 'hostSessionId');
    
    if (sessionId !== hostId) return;
    
    await redis.hset(`room:${roomId}:players:${targetSessionId}`, 'team', team);
    io.to(targetSessionId).emit('role:assigned', { team });
    io.to(roomId).emit('players:updated', await getPlayerList(roomId));
  });
  
  // 게임 시작 (방장)
  socket.on('game:start', async () => {
    const { roomId, sessionId } = socket.data;
    const hostId = await redis.hget(`room:${roomId}`, 'hostSessionId');
    
    if (sessionId !== hostId) return;
    
    const players = await getPlayerList(roomId);
    const unassigned = players.filter(p => p.team === 'unassigned');
    if (unassigned.length > 0) {
      socket.emit('error', { message: '모든 역할을 배정해주세요' });
      return;
    }
    
    const thieves = players.filter(p => p.team === 'thief');
    const duration = parseInt(await redis.hget(`room:${roomId}`, 'duration'));
    
    await redis.hset(`room:${roomId}`, { status: 'playing', startedAt: Date.now() });
    await redis.hset(`room:${roomId}:state`, {
      remainingTime: duration,
      aliveThieves: thieves.length,
      deadThieves: 0,
    });
    
    startGameTimer(roomId, duration);
    io.to(roomId).emit('game:started', { startedAt: Date.now(), duration });
  });
  
  // 검거 요청
  socket.on('arrest:request', async ({ targetSessionId }) => {
    const { roomId, sessionId } = socket.data;
    const requestId = `${Date.now()}-${sessionId}`;
    const police = await redis.hgetall(`room:${roomId}:players:${sessionId}`);
    
    io.to(targetSessionId).emit('arrest:requested', {
      requestId,
      policeSessionId: sessionId,
      policeNickname: police.nickname,
    });
  });
  
  // 검거 응답
  socket.on('arrest:respond', async ({ requestId, accepted }) => {
    const { roomId, sessionId } = socket.data;
    
    if (accepted) {
      await arrestPlayer(roomId, sessionId);
      const player = await redis.hgetall(`room:${roomId}:players:${sessionId}`);
      io.to(roomId).emit('player:arrested', { sessionId, nickname: player.nickname });
      
      const policeId = requestId.split('-')[1];
      await redis.hincrby(`room:${roomId}:players:${policeId}`, 'arrestCount', 1);
      await checkGameEnd(roomId);
    }
  });
  
  // 영역 이탈
  socket.on('boundary:exit', () => {
    const { roomId, sessionId } = socket.data;
    
    const timer = setTimeout(async () => {
      await arrestPlayer(roomId, sessionId);
      const player = await redis.hgetall(`room:${roomId}:players:${sessionId}`);
      io.to(roomId).emit('player:auto_arrested', {
        sessionId,
        nickname: player.nickname,
        reason: 'out_of_bounds',
      });
      await checkGameEnd(roomId);
    }, 60000);
    
    boundaryTimers.set(sessionId, timer);
  });
  
  // 영역 복귀
  socket.on('boundary:enter', () => {
    const timer = boundaryTimers.get(socket.data.sessionId);
    if (timer) {
      clearTimeout(timer);
      boundaryTimers.delete(socket.data.sessionId);
    }
  });
  
  // 탈옥
  socket.on('jailbreak:trigger', async () => {
    const { roomId, sessionId } = socket.data;
    
    const playerKeys = await redis.keys(`room:${roomId}:players:*`);
    const revivedPlayers = [];
    
    for (const key of playerKeys) {
      const player = await redis.hgetall(key);
      if (player.team === 'thief' && player.status === 'dead') {
        await redis.hset(key, 'status', 'alive');
        revivedPlayers.push(key.split(':').pop());
      }
    }
    
    if (revivedPlayers.length > 0) {
      await redis.hincrby(`room:${roomId}:state`, 'aliveThieves', revivedPlayers.length);
      await redis.hincrby(`room:${roomId}:state`, 'deadThieves', -revivedPlayers.length);
    }
    
    await redis.hincrby(`room:${roomId}:players:${sessionId}`, 'rescueCount', 1);
    
    io.to(roomId).emit('jailbreak:success', {
      triggeredBy: sessionId,
      revivedPlayers,
      playSiren: true,
    });
  });
  
  // 채팅
  socket.on('chat:send', ({ targetSessionId, message }) => {
    io.to(targetSessionId).emit('chat:received', {
      from: socket.data.sessionId,
      message,
      timestamp: Date.now(),
    });
  });
});

// ==================== Helpers ====================

async function getPlayerList(roomId) {
  const keys = await redis.keys(`room:${roomId}:players:*`);
  const players = [];
  for (const key of keys) {
    const sessionId = key.split(':').pop();
    const data = await redis.hgetall(key);
    players.push({ sessionId, ...data });
  }
  return players;
}

async function arrestPlayer(roomId, sessionId) {
  await redis.hset(`room:${roomId}:players:${sessionId}`, 'status', 'dead');
  await redis.hincrby(`room:${roomId}:state`, 'aliveThieves', -1);
  await redis.hincrby(`room:${roomId}:state`, 'deadThieves', 1);
}

async function checkGameEnd(roomId) {
  const alive = await redis.hget(`room:${roomId}:state`, 'aliveThieves');
  if (parseInt(alive) === 0) {
    await endGame(roomId, 'police');
  }
}

async function endGame(roomId, winner) {
  const timer = gameTimers.get(roomId);
  if (timer) clearInterval(timer);
  
  await redis.hset(`room:${roomId}`, 'status', 'finished');
  const players = await getPlayerList(roomId);
  
  io.to(roomId).emit('game:ended', { winner, mvp: calculateMVP(players) });
}

function calculateMVP(players) {
  const police = players.filter(p => p.team === 'police');
  const thieves = players.filter(p => p.team === 'thief');
  
  const arrestKing = police.sort((a, b) => b.arrestCount - a.arrestCount)[0];
  const surviveKing = thieves.find(t => t.status === 'alive');
  const rescueKing = thieves.sort((a, b) => b.rescueCount - a.rescueCount)[0];
  
  return {
    arrestKing: arrestKing?.arrestCount > 0 ? arrestKing : null,
    surviveKing,
    rescueKing: rescueKing?.rescueCount > 0 ? rescueKing : null,
  };
}

function startGameTimer(roomId, duration) {
  let remaining = duration;
  
  const timer = setInterval(async () => {
    remaining -= 1;
    await redis.hset(`room:${roomId}:state`, 'remainingTime', remaining);
    io.to(roomId).emit('game:tick', { remainingTime: remaining });
    
    if (remaining <= 0) {
      clearInterval(timer);
      const alive = await redis.hget(`room:${roomId}:state`, 'aliveThieves');
      await endGame(roomId, parseInt(alive) > 0 ? 'thief' : 'police');
    }
  }, 1000);
  
  gameTimers.set(roomId, timer);
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`서버: http://localhost:${PORT}`));
```

---

## 📁 프로젝트 구조

### Flutter (Client)
```
lib/
├── main.dart
├── app/
│   ├── routes.dart
│   └── bindings.dart
├── controllers/
│   ├── session_controller.dart
│   ├── room_controller.dart
│   ├── game_controller.dart
│   └── chat_controller.dart
├── services/
│   ├── socket_service.dart
│   ├── geofence_service.dart     # Method Channel
│   ├── sound_service.dart
│   └── health_service.dart
├── models/
│   ├── room.dart
│   ├── player.dart
│   └── game_state.dart
├── views/
│   ├── nickname_view.dart
│   ├── lobby/
│   │   ├── create_room_view.dart
│   │   ├── map_setup_view.dart
│   │   ├── join_room_view.dart
│   │   └── waiting_room_view.dart
│   ├── game/
│   │   ├── police_game_view.dart   # 경찰 전용
│   │   ├── thief_game_view.dart    # 도둑 전용
│   │   └── boundary_warning_dialog.dart
│   └── result/
│       └── result_view.dart
├── widgets/
│   ├── otp_display.dart
│   ├── player_card.dart
│   ├── role_toggle.dart
│   ├── jailbreak_button.dart
│   └── arrest_request_dialog.dart
└── utils/
    ├── geo_utils.dart
    └── constants.dart

ios/Runner/
├── AppDelegate.swift              # Method Channel 설정
├── GeofenceManager.swift          # Core Location

android/app/src/main/kotlin/com/carrot/hideseek/
├── MainActivity.kt                # Method Channel 설정
├── GeofenceManager.kt             # GeofencingClient
└── GeofenceBroadcastReceiver.kt
```

### Express.js (Server)
```
server/
├── index.js
├── package.json
├── .env
└── Dockerfile
```

---

## ✅ 개발 체크리스트

### Phase 1: 기본 구조
- [ ] Flutter 프로젝트 세팅
- [ ] Express.js 서버 세팅
- [ ] Redis 연결
- [ ] 세션 API

### Phase 2: 네이티브 Geofencing
- [ ] iOS GeofenceManager.swift
- [ ] Android GeofenceManager.kt
- [ ] Method Channel 연결

### Phase 3: 로비
- [ ] 지도 Polygon 구역 설정
- [ ] 감옥 위치 설정
- [ ] OTP 30초 갱신
- [ ] 역할 배정 (방장)

### Phase 4: 게임
- [ ] 경찰/도둑 화면 분리
- [ ] 검거 요청/응답
- [ ] 탈옥 + 사이렌
- [ ] 영역 이탈 경고

### Phase 5: 마무리
- [ ] 결과 화면
- [ ] MVP 계산
- [ ] 만보기 연동

---

## ⚠️ 주의사항

1. **역할 배정은 방장만** - 플레이어 직접 선택 X
2. **경찰/도둑 화면 분리** - 도둑은 경찰 안 보임
3. **서버 UUID 사용** - 기기 UUID X
4. **Redis Only** - PostgreSQL 불필요
5. **네이티브 Geofencing** - 원형만 지원, Polygon은 서버 Turf.js
6. **iOS**: Info.plist 위치 권한 설명 필수
7. **Android**: Manifest 권한 + BroadcastReceiver 등록
