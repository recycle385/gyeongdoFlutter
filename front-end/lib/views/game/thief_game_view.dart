import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../view_models/game_controller.dart';
import '../../app/theme.dart';
import '../../models/player_model.dart';
import '../../widgets/map_modal.dart';

/// 도둑 게임 화면
class ThiefGameView extends GetView<GameController> {
  const ThiefGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.thiefRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.run_circle, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '도둑',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 실시간 표시
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '실시간 (LIVE)',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 다크모드 토글
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // TODO: 다크모드 토글
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // 체포된 경우 감옥 화면 표시
          if (controller.isDead) {
            return _buildJailView();
          }

          // 생존 중인 경우 일반 게임 화면
          return Column(
            children: [
              // 타이머
              _buildTimer(),

              const SizedBox(height: AppSpacing.md),

              // 생존자/체포자 통계
              _buildStats(),

              const SizedBox(height: AppSpacing.md),

              // 도둑 동료 목록
              Expanded(
                child: _buildThiefList(),
              ),

              // 운동 통계
              _buildExerciseStats(),

              // 지도 보기 버튼
              _buildMapButton(),
            ],
          );
        }),
      ),
    );
  }

  /// 타이머
  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Obx(() {
            final time = controller.gameState.value?.formattedTime ?? '--:--';
            return Text(
              time,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: -2,
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '남은 시간',
            style: AppTextStyles.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 생존자/체포자 통계
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // 생존자 (Runner)
          Expanded(
            child: Obx(() {
              final aliveCount = controller.aliveThieves.length;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppTheme.successGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '생존자 (Runner)',
                      style: AppTextStyles.body2.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$aliveCount',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(width: AppSpacing.md),

          // 체포자 (Jail)
          Expanded(
            child: Obx(() {
              final deadCount = controller.deadThieves.length;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppTheme.thiefRed.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '체포자 (Jail)',
                      style: AppTextStyles.body2.copyWith(
                        color: AppTheme.thiefRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$deadCount',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.thiefRed,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 도둑 동료 목록
  Widget _buildThiefList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '도둑 동료',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() {
                  final total = controller.thiefPlayers.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.thiefRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '총 ${total}명',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.thiefRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // 목록
          Expanded(
            child: Obx(() {
              final thieves = controller.thiefPlayers;
              if (thieves.isEmpty) {
                return const Center(
                  child: Text('도둑이 없습니다'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: thieves.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final player = thieves[index];
                  return _buildPlayerCard(player);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 플레이어 카드
  Widget _buildPlayerCard(PlayerModel player) {
    final isAlive = player.isAlive;
    final isMe = player.sessionId == controller.mySessionId.value;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isAlive ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isMe
              ? AppTheme.carrotOrange
              : (isAlive ? Colors.grey[300]! : Colors.grey[400]!),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            backgroundColor: isAlive ? AppTheme.successGreen : AppTheme.deadGray,
            child: Text(
              isAlive ? '🏃' : '🔒',
              style: const TextStyle(fontSize: 20),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // 정보
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
                        color: isAlive ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAlive ? '도주 중' : '감옥',
                      style: AppTextStyles.caption.copyWith(
                        color: isAlive ? AppTheme.successGreen : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 채팅 버튼
          if (!isMe)
            IconButton(
              onPressed: () {
                // TODO: 채팅 기능
                Get.snackbar(
                  '채팅',
                  '${player.nickname}님과의 채팅 기능은 곧 추가됩니다',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              color: AppTheme.thiefRed,
            ),
        ],
      ),
    );
  }

  /// 운동 통계
  Widget _buildExerciseStats() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Obx(() {
        final me = controller.me;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '내 속도',
              '${(me?.distance ?? 0.0).toStringAsFixed(1)}',
              'km/h',
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildStatItem(
              '이동 거리',
              '${(me?.distance ?? 0.0).toStringAsFixed(1)}',
              'km',
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildStatItem(
              '칼로리',
              '${(me?.calories ?? 0.0).toInt()}',
              'kcaL',
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 지도 보기 버튼
  Widget _buildMapButton() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: OutlinedButton(
        onPressed: () {
          // 지도 모달 표시
          Get.dialog(
            MapModal(
              myLat: controller.currentLat ?? 37.5665, // 서울 시청 (기본값)
              myLng: controller.currentLng ?? 126.9780,
              jailLat: 37.5655, // TODO: 서버에서 감옥 위치 받기
              jailLng: 126.9770,
              isPolice: false,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: BorderSide(color: AppTheme.thiefRed, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 24, color: AppTheme.thiefRed),
            const SizedBox(width: 8),
            Text(
              '지도 보기',
              style: AppTextStyles.body1.copyWith(
                color: AppTheme.thiefRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 감옥 화면 (체포당한 경우)
  Widget _buildJailView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 감옥 아이콘
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.deadGray.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: 60,
              color: AppTheme.deadGray,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            '체포되었습니다',
            style: AppTextStyles.h2.copyWith(
              color: AppTheme.deadGray,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            '동료가 탈옥을 시도할 때까지 기다리세요',
            style: AppTextStyles.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 탈옥 진행 상태
          Obx(() {
            if (controller.jailbreakInProgress.value) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 48,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '탈옥 진행 중!',
                      style: AppTextStyles.h3.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Obx(() {
                      return Text(
                        '${controller.jailbreakTimeRemaining.value}초 남음',
                        style: AppTextStyles.body1.copyWith(
                          color: AppTheme.successGreen,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }),

          const SizedBox(height: AppSpacing.xl),

          // 게임 정보
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Column(
              children: [
                _buildJailStat(
                  '남은 시간',
                  controller.gameState.value?.formattedTime ?? '--:--',
                ),
                const Divider(height: 24),
                Obx(() {
                  final aliveCount = controller.aliveThieves.length;
                  return _buildJailStat(
                    '생존 동료',
                    '$aliveCount명',
                  );
                }),
                const Divider(height: 24),
                Obx(() {
                  final deadCount = controller.deadThieves.length;
                  return _buildJailStat(
                    '감옥 인원',
                    '$deadCount명',
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJailStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body1.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
