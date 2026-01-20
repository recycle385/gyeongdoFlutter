import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme.dart';
import '../../services/storage_service.dart';

/// 로비 화면 (방 만들기 / 참여하기 선택)
class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final nickname = storage.nickname ?? '플레이어';

    return Scaffold(
      appBar: AppBar(
        title: const Text('당근 술래잡기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showProfileDialog(context, nickname);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 환영 메시지
              Text(
                '안녕하세요,\n$nickname님!',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                '게임을 시작하려면 방을 만들거나\n기존 방에 참여하세요.',
                style: AppTextStyles.body1.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 방 만들기 버튼
              _buildActionCard(
                context: context,
                title: '방 만들기',
                description: '지도에서 게임 구역을 설정하고\n친구들을 초대하세요',
                icon: Icons.add_circle_outline,
                color: AppTheme.carrotOrange,
                onTap: () {
                  Get.toNamed('/create-room');
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 참여하기 버튼
              _buildActionCard(
                context: context,
                title: '참여하기',
                description: 'OTP 코드를 입력하여\n친구의 방에 참여하세요',
                icon: Icons.login,
                color: AppTheme.policeBlue,
                onTap: () {
                  Get.toNamed('/join-room');
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 하단 정보
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '방장만 게임 구역을 설정하고\n역할을 배정할 수 있습니다.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(color: color),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),

              // 화살표
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, String nickname) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              nickname,
              style: AppTextStyles.h3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
