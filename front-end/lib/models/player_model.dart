import '../app/constants.dart';

/// 플레이어 모델
class PlayerModel {
  final String sessionId;
  final String nickname;
  final String role; // 'host' or 'player'
  final TeamType team;
  final PlayerStatus status;
  final int arrestCount; // 체포한 횟수 (경찰)
  final int rescueCount; // 구출한 횟수 (도둑)
  final double distance; // 이동 거리 (km)
  final double calories; // 소모 칼로리 (kcal)
  final int steps; // 걸음 수

  PlayerModel({
    required this.sessionId,
    required this.nickname,
    this.role = 'player',
    this.team = TeamType.unassigned,
    this.status = PlayerStatus.alive,
    this.arrestCount = 0,
    this.rescueCount = 0,
    this.distance = 0.0,
    this.calories = 0.0,
    this.steps = 0,
  });

  // JSON to Model
  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      sessionId: json['sessionId'] ?? '',
      nickname: json['nickname'] ?? '',
      role: json['role'] ?? 'player',
      team: TeamType.fromString(json['team'] ?? 'unassigned'),
      status: PlayerStatus.fromString(json['status'] ?? 'alive'),
      arrestCount: int.tryParse(json['arrestCount']?.toString() ?? '0') ?? 0,
      rescueCount: int.tryParse(json['rescueCount']?.toString() ?? '0') ?? 0,
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
      calories: double.tryParse(json['calories']?.toString() ?? '0') ?? 0.0,
      steps: int.tryParse(json['steps']?.toString() ?? '0') ?? 0,
    );
  }

  // Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'nickname': nickname,
      'role': role,
      'team': team.value,
      'status': status.value,
      'arrestCount': arrestCount,
      'rescueCount': rescueCount,
      'distance': distance,
      'calories': calories,
      'steps': steps,
    };
  }

  // CopyWith
  PlayerModel copyWith({
    String? sessionId,
    String? nickname,
    String? role,
    TeamType? team,
    PlayerStatus? status,
    int? arrestCount,
    int? rescueCount,
    double? distance,
    double? calories,
    int? steps,
  }) {
    return PlayerModel(
      sessionId: sessionId ?? this.sessionId,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      team: team ?? this.team,
      status: status ?? this.status,
      arrestCount: arrestCount ?? this.arrestCount,
      rescueCount: rescueCount ?? this.rescueCount,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      steps: steps ?? this.steps,
    );
  }

  // 편의 메서드
  bool get isHost => role == 'host';
  bool get isAlive => status == PlayerStatus.alive;
  bool get isDead => status == PlayerStatus.dead;
  bool get isPolice => team == TeamType.police;
  bool get isThief => team == TeamType.thief;
  bool get isUnassigned => team == TeamType.unassigned;

  @override
  String toString() {
    return 'PlayerModel(sessionId: $sessionId, nickname: $nickname, team: ${team.value}, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerModel && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;
}
