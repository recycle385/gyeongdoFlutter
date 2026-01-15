/// 게임 상태 모델
class GameStateModel {
  final int remainingTime; // 남은 시간 (초)
  final int aliveThieves; // 생존 도둑 수
  final int deadThieves; // 체포된 도둑 수
  final DateTime? startedAt; // 게임 시작 시간

  GameStateModel({
    required this.remainingTime,
    required this.aliveThieves,
    required this.deadThieves,
    this.startedAt,
  });

  // JSON to Model
  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      remainingTime: int.tryParse(json['remainingTime']?.toString() ?? '0') ?? 0,
      aliveThieves: int.tryParse(json['aliveThieves']?.toString() ?? '0') ?? 0,
      deadThieves: int.tryParse(json['deadThieves']?.toString() ?? '0') ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['startedAt'].toString()) ?? 0)
          : null,
    );
  }

  // Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'remainingTime': remainingTime,
      'aliveThieves': aliveThieves,
      'deadThieves': deadThieves,
      'startedAt': startedAt?.millisecondsSinceEpoch,
    };
  }

  // CopyWith
  GameStateModel copyWith({
    int? remainingTime,
    int? aliveThieves,
    int? deadThieves,
    DateTime? startedAt,
  }) {
    return GameStateModel(
      remainingTime: remainingTime ?? this.remainingTime,
      aliveThieves: aliveThieves ?? this.aliveThieves,
      deadThieves: deadThieves ?? this.deadThieves,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  // 편의 메서드
  int get totalThieves => aliveThieves + deadThieves;

  String get formattedTime {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isTimeUp => remainingTime <= 0;

  @override
  String toString() {
    return 'GameStateModel(remainingTime: $remainingTime, aliveThieves: $aliveThieves, deadThieves: $deadThieves)';
  }
}
