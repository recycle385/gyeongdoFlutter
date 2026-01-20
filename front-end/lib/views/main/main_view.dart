import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

/// 메인 화면 (방 생성 / 입장 선택)
class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // 로고 및 타이틀
              Column(
                children: [
                  // 당근 아이콘
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppTheme.carrotOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      size: 80,
                      color: AppTheme.carrotOrange,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    '당근 술래잡기',
                    style: AppTextStyles.h1.copyWith(
                      color: AppTheme.carrotOrange,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    '친구들과 함께하는 실시간 술래잡기',
                    style: AppTextStyles.body1.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const Spacer(),

              // 방 생성 버튼
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(Routes.GPS_CONSENT, arguments: {'mode': 'create'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.carrotOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '방 생성',
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 입장 버튼
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: () {
                    Get.toNamed(Routes.JOIN_ROOM);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.policeBlue,
                    side: const BorderSide(color: AppTheme.policeBlue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '입장',
                        style: AppTextStyles.h3.copyWith(color: AppTheme.policeBlue),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
