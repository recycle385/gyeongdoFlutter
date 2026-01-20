import 'package:flutter/material.dart';

/// 앱 전체 상수 관리
class AppConstants {
  // 서버 URL
  // Android 에뮬레이터에서는 10.0.2.2가 호스트 PC를 가리킴
  // 실제 디바이스 테스트 시에는 PC의 실제 IP 주소로 변경 필요
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String apiUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;

  // 게임 설정
  static const int defaultGameDuration = 1800; // 30분 (초 단위)
  static const double defaultJailRadius = 15.0; // 감옥 반경 (미터)
  static const int otpRefreshInterval = 30; // OTP 갱신 주기 (초)
  static const int otpLength = 4; // OTP 코드 길이

  // 영역 이탈 설정
  static const int boundaryExitWarningTime = 60; // 복귀 제한 시간 (초)

  // 탈옥 설정
  static const double jailbreakActivationRadius = 15.0; // 탈옥 활성화 반경 (미터)

  // 검거 요청 설정
  static const int arrestRequestTimeout = 10; // 검거 요청 응답 제한 시간 (초)

  // Geofence 설정
  static const String geofencePlayAreaId = 'play_area';
  static const String geofenceJailId = 'jail';

  // 지도 설정
  static const double mapDefaultZoom = 15.0;
  static const double mapMinZoom = 10.0;
  static const double mapMaxZoom = 20.0;

  // 로컬 저장소 키
  static const String storageKeySessionId = 'sessionId';
  static const String storageKeyNickname = 'nickname';
  static const String storageKeyRoomId = 'roomId';
  static const String storageKeyGender = 'gender';

  // 정규식
  static final RegExp nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$');
  static final RegExp otpRegex = RegExp(r'^\d{4}$');

  // 에러 메시지
  static const String errorNetworkFailed = '네트워크 연결에 실패했습니다.';
  static const String errorInvalidNickname = '닉네임은 2-10자의 한글, 영문, 숫자만 가능합니다.';
  static const String errorInvalidOtp = 'OTP 코드는 4자리 숫자입니다.';
  static const String errorRoomNotFound = '방을 찾을 수 없습니다.';
  static const String errorSessionNotFound = '세션을 찾을 수 없습니다.';
  static const String errorPermissionDenied = '권한이 거부되었습니다.';
  static const String errorLocationServiceDisabled = '위치 서비스가 비활성화되어 있습니다.';

  // 성공 메시지
  static const String successRoomCreated = '방이 생성되었습니다.';
  static const String successRoomJoined = '방에 참여했습니다.';
  static const String successGameStarted = '게임이 시작되었습니다.';
}

/// 팀 타입
enum TeamType {
  unassigned('unassigned', '미배정', '⚪', Colors.grey),
  police('police', '경찰', '👮', Colors.blue),
  thief('thief', '도둑', '🦹', Colors.red);

  const TeamType(this.value, this.label, this.emoji, this.color);
  final String value;
  final String label;
  final String emoji;
  final Color color;

  static TeamType fromString(String value) {
    return TeamType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TeamType.unassigned,
    );
  }
}

/// 플레이어 상태
enum PlayerStatus {
  alive('alive', '생존', '🟢'),
  dead('dead', '체포됨', '🔴');

  const PlayerStatus(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static PlayerStatus fromString(String value) {
    return PlayerStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlayerStatus.alive,
    );
  }
}

/// 방 상태
enum RoomStatus {
  waiting('waiting', '대기 중'),
  playing('playing', '진행 중'),
  finished('finished', '종료됨');

  const RoomStatus(this.value, this.label);
  final String value;
  final String label;

  static RoomStatus fromString(String value) {
    return RoomStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoomStatus.waiting,
    );
  }
}

/// 게임 승자
enum GameWinner {
  police('police', '경찰 승리', '👮'),
  thief('thief', '도둑 승리', '🦹'),
  draw('draw', '무승부', '🤝');

  const GameWinner(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static GameWinner fromString(String value) {
    return GameWinner.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GameWinner.draw,
    );
  }
}
