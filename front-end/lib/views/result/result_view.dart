import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../models/player_model.dart';
import '../../models/game_state_model.dart';

/// 게임 결과 화면
class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    // arguments에서 데이터 받기
    final args = Get.arguments as Map<String, dynamic>?;
    final winner = args?['winner'] as GameWinner? ?? GameWinner.draw;
    final finalState = args?['finalState'] as GameStateModel?;
    final players = (args?['players'] as List?)
        ?.cast<PlayerModel>() ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // 승리/패배 배너
            _buildWinnerBanner(winner),

            // 최종 통계
            _buildFinalStats(finalState),

            // 플레이어 순위
            Expanded(
              child: _buildPlayerRanking(players),
            ),

            // 로비로 돌아가기 버튼
            _buildBackToLobbyButton(),
          ],
        ),
      ),
    );
  }

  /// 승리/패배 배너
  Widget _buildWinnerBanner(GameWinner winner) {
    String title;
    String emoji;
    Color backgroundColor;
    Color textColor;

    switch (winner) {
      case GameWinner.police:
        title = '경찰 승리!';
        emoji = '👮';
        backgroundColor = AppTheme.policeBlue;
        textColor = Colors.white;
        break;
      case GameWinner.thief:
        title = '도둑 승리!';
        emoji = '🏃';
        backgroundColor = AppTheme.thiefRed;
        textColor = Colors.white;
        break;
      case GameWinner.draw:
        title = '무승부';
        emoji = '🤝';
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '게임이 종료되었습니다',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 최종 통계
  Widget _buildFinalStats(GameStateModel? finalState) {
    if (finalState == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            '게임 시간',
            finalState.formattedTime,
            Icons.timer,
            AppTheme.carrotOrange,
          ),
          Container(width: 1, height: 60, color: Colors.grey[300]),
          _buildStatCard(
            '생존자',
            '${finalState.aliveThieves}명',
            Icons.person,
            AppTheme.successGreen,
          ),
          Container(width: 1, height: 60, color: Colors.grey[300]),
          _buildStatCard(
            '체포자',
            '${finalState.deadThieves}명',
            Icons.lock,
            AppTheme.thiefRed,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 플레이어 순위
  Widget _buildPlayerRanking(List<PlayerModel> players) {
    if (players.isEmpty) {
      return const Center(
        child: Text('플레이어 정보가 없습니다'),
      );
    }

    // 거리순으로 정렬
    final sortedPlayers = List<PlayerModel>.from(players)
      ..sort((a, b) => b.distance.compareTo(a.distance));

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
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '플레이어 통계',
                  style: AppTextStyles.h3,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 순위 목록
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sortedPlayers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final rank = index + 1;
                return _buildPlayerCard(player, rank);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 플레이어 카드
  Widget _buildPlayerCard(PlayerModel player, int rank) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.grey[300]!;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: rank <= 3 ? rankColor : Colors.grey[300]!,
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 순위 및 이름
          Row(
            children: [
              // 순위 배지
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // 이름 및 팀
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.nickname,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          player.isPolice ? Icons.shield : Icons.run_circle,
                          size: 14,
                          color: player.isPolice
                              ? AppTheme.policeBlue
                              : AppTheme.thiefRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          player.team.label,
                          style: AppTextStyles.caption.copyWith(
                            color: player.isPolice
                                ? AppTheme.policeBlue
                                : AppTheme.thiefRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // MVP 표시 (1등)
              if (rank == 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MVP',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 통계
          Row(
            children: [
              Expanded(
                child: _buildPlayerStat(
                  '이동거리',
                  '${player.distance.toStringAsFixed(2)} km',
                  Icons.map,
                ),
              ),
              Expanded(
                child: _buildPlayerStat(
                  '칼로리',
                  '${player.calories.toInt()} kcal',
                  Icons.local_fire_department,
                ),
              ),
              Expanded(
                child: _buildPlayerStat(
                  '걸음수',
                  '${player.steps}',
                  Icons.directions_walk,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              if (player.isPolice)
                Expanded(
                  child: _buildPlayerStat(
                    '체포 횟수',
                    '${player.arrestCount}',
                    Icons.gavel,
                  ),
                ),
              if (player.isThief) ...[
                Expanded(
                  child: _buildPlayerStat(
                    '구출 횟수',
                    '${player.rescueCount}',
                    Icons.favorite,
                  ),
                ),
                Expanded(
                  child: _buildPlayerStat(
                    '상태',
                    player.isAlive ? '생존' : '체포됨',
                    player.isAlive ? Icons.check_circle : Icons.cancel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 로비로 돌아가기 버튼
  Widget _buildBackToLobbyButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ElevatedButton(
        onPressed: () {
          Get.offAllNamed(Routes.LOBBY);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.carrotOrange,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 24),
            const SizedBox(width: 8),
            Text(
              '로비로 돌아가기',
              style: AppTextStyles.body1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
