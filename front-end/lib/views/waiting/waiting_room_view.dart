import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../view_models/waiting_room_controller.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../models/player_model.dart';

/// 대기실 화면
class WaitingRoomView extends GetView<WaitingRoomController> {
  const WaitingRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대기실'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 방 정보 재조회 (필요시 구현)
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // OTP 코드 표시 (방장만)
            Obx(() {
              if (controller.isHost.value) {
                return _buildOtpSection();
              }
              return const SizedBox.shrink();
            }),

            // 참가자 통계
            _buildPlayerStats(),

            const Divider(),

            // 참가자 목록
            Expanded(
              child: Obx(() {
                if (controller.players.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: controller.players.length,
                  itemBuilder: (context, index) {
                    final player = controller.players[index];
                    return _buildPlayerCard(player);
                  },
                );
              }),
            ),

            // 게임 시작 버튼 (방장만)
            Obx(() {
              if (controller.isHost.value) {
                return _buildStartGameButton();
              }
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  '방장이 게임을 시작할 때까지 기다려주세요...',
                  style: AppTextStyles.body2.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// OTP 코드 섹션 (방장 전용)
  Widget _buildOtpSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.carrotOrange,
            AppTheme.carrotOrangeDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.carrotOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'OTP 코드',
            style: AppTextStyles.body1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() {
            return Text(
              controller.otpCode.value.isEmpty
                  ? '----'
                  : controller.otpCode.value,
              style: AppTextStyles.otpCode.copyWith(
                color: Colors.white,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          Obx(() {
            return Text(
              '${controller.otpTimeRemaining.value}초 후 갱신',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '친구들에게 이 코드를 공유하세요',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 참가자 통계
  Widget _buildPlayerStats() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '총 인원',
                controller.players.length.toString(),
                Icons.people,
                Colors.grey,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '경찰',
                controller.policeCount.toString(),
                Icons.shield,
                AppTheme.policeBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '도둑',
                controller.thiefCount.toString(),
                Icons.run_circle,
                AppTheme.thiefRed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '미배정',
                controller.unassignedCount.toString(),
                Icons.help_outline,
                Colors.orange,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// 플레이어 카드
  Widget _buildPlayerCard(PlayerModel player) {
    final isMe = player.sessionId == controller.mySessionId.value;
    final isHost = controller.isHost.value;

    return Obx(() {
      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        elevation: isMe ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          side: isMe
              ? BorderSide(color: AppTheme.carrotOrange, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 아바타
              CircleAvatar(
                backgroundColor: _getTeamColor(player.team),
                child: Text(
                  player.team.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // 이름 및 상태
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.nickname,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.carrotOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '나',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (player.isHost) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '방장',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      player.team.label,
                      style: AppTextStyles.body2.copyWith(
                        color: _getTeamColor(player.team),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // 역할 변경 버튼 (방장만, 자신 제외)
              if (isHost && !isMe) ...[
                PopupMenuButton<TeamType>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (TeamType team) {
                    controller.assignRole(player, team);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: TeamType.police,
                      child: Row(
                        children: [
                          Text(TeamType.police.emoji),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('경찰로 지정'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: TeamType.thief,
                      child: Row(
                        children: [
                          Text(TeamType.thief.emoji),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('도둑으로 지정'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// 게임 시작 버튼
  Widget _buildStartGameButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        final canStart = controller.canStartGame.value;
        return ElevatedButton(
          onPressed: canStart ? controller.startGame : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            backgroundColor: AppTheme.carrotOrange,
            disabledBackgroundColor: Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                canStart ? '게임 시작' : '모든 역할을 배정해주세요',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 팀 색상 가져오기
  Color _getTeamColor(TeamType team) {
    switch (team) {
      case TeamType.police:
        return AppTheme.policeBlue;
      case TeamType.thief:
        return AppTheme.thiefRed;
      case TeamType.unassigned:
        return Colors.grey;
    }
  }
}
