import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../app/constants.dart';

/// 방 모델
class RoomModel {
  final String roomId;
  final String hostSessionId;
  final RoomStatus status;
  final List<NLatLng> playArea; // 활동 구역 (폴리곤)
  final NLatLng jailLocation; // 감옥 위치
  final double jailRadius; // 감옥 반경 (미터)
  final int duration; // 게임 시간 (초)
  final DateTime? startedAt; // 게임 시작 시간

  RoomModel({
    required this.roomId,
    required this.hostSessionId,
    this.status = RoomStatus.waiting,
    required this.playArea,
    required this.jailLocation,
    this.jailRadius = AppConstants.defaultJailRadius,
    this.duration = AppConstants.defaultGameDuration,
    this.startedAt,
  });

  // JSON to Model
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // playArea 파싱 (GeoJSON Polygon 형식)
    List<NLatLng> playAreaCoords = [];
    if (json['playArea'] != null) {
      try {
        final playAreaData =
            json['playArea'] is String ? json['playArea'] : json['playArea'];
        if (playAreaData is Map) {
          final coordinates = playAreaData['coordinates'] as List?;
          if (coordinates != null && coordinates.isNotEmpty) {
            final ring = coordinates[0] as List;
            playAreaCoords = ring.map((coord) {
              return NLatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('playArea 파싱 실패: $e');
      }
    }

    // jailLocation 파싱 (GeoJSON Point 형식)
    NLatLng jailCoord = const NLatLng(37.5665, 126.9780); // 기본값
    if (json['jailLocation'] != null) {
      try {
        final jailData =
            json['jailLocation'] is String ? json['jailLocation'] : json['jailLocation'];
        if (jailData is Map) {
          final coordinates = jailData['coordinates'] as List?;
          if (coordinates != null && coordinates.length >= 2) {
            jailCoord = NLatLng(
              (coordinates[1] as num).toDouble(),
              (coordinates[0] as num).toDouble(),
            );
          }
        }
      } catch (e) {
        debugPrint('jailLocation 파싱 실패: $e');
      }
    }

    return RoomModel(
      roomId: json['roomId'] ?? '',
      hostSessionId: json['hostSessionId'] ?? '',
      status: RoomStatus.fromString(json['status'] ?? 'waiting'),
      playArea: playAreaCoords,
      jailLocation: jailCoord,
      jailRadius: double.tryParse(json['jailRadius']?.toString() ?? '15') ?? 15.0,
      duration: int.tryParse(json['duration']?.toString() ?? '1800') ?? 1800,
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['startedAt'].toString()) ?? 0)
          : null,
    );
  }

  // Model to JSON (GeoJSON 형식)
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'hostSessionId': hostSessionId,
      'status': status.value,
      'playArea': {
        'type': 'Polygon',
        'coordinates': [
          playArea.map((coord) => [coord.longitude, coord.latitude]).toList(),
        ],
      },
      'jailLocation': {
        'type': 'Point',
        'coordinates': [jailLocation.longitude, jailLocation.latitude],
      },
      'jailRadius': jailRadius,
      'duration': duration,
      'startedAt': startedAt?.millisecondsSinceEpoch,
    };
  }

  // CopyWith
  RoomModel copyWith({
    String? roomId,
    String? hostSessionId,
    RoomStatus? status,
    List<NLatLng>? playArea,
    NLatLng? jailLocation,
    double? jailRadius,
    int? duration,
    DateTime? startedAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      hostSessionId: hostSessionId ?? this.hostSessionId,
      status: status ?? this.status,
      playArea: playArea ?? this.playArea,
      jailLocation: jailLocation ?? this.jailLocation,
      jailRadius: jailRadius ?? this.jailRadius,
      duration: duration ?? this.duration,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  // 편의 메서드
  bool get isWaiting => status == RoomStatus.waiting;
  bool get isPlaying => status == RoomStatus.playing;
  bool get isFinished => status == RoomStatus.finished;

  String get formattedDuration {
    final minutes = duration ~/ 60;
    return '$minutes분';
  }

  @override
  String toString() {
    return 'RoomModel(roomId: $roomId, status: ${status.value}, duration: $duration)';
  }
}
