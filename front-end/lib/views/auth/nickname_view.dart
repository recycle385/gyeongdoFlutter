import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../view_models/auth_controller.dart';
import '../../app/theme.dart';

/// 닉네임 설정 화면
class NicknameView extends GetView<AuthController> {
  const NicknameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 및 타이틀
                Icon(
                  Icons.location_on,
                  size: 80,
                  color: AppTheme.carrotOrange,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  '당근 술래잡기',
                  style: AppTextStyles.h1.copyWith(
                    color: AppTheme.carrotOrange,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  '실시간 위치 공유 없이,\n게임 룰 판정과 결과 정산에 집중',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // 닉네임 입력
                Text(
                  '닉네임을 입력하세요',
                  style: AppTextStyles.h3,
                ),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: controller.nicknameController,
                  validator: controller.validateNickname,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: '2-10자의 한글, 영문, 숫자',
                    prefixIcon: const Icon(Icons.person),
                    counterText: '',
                    errorMaxLines: 2,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => controller.setNickname(),
                ),

                const SizedBox(height: AppSpacing.md),

                // 에러 메시지
                Obx(() {
                  if (controller.errorMessage.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: AppTheme.dangerRed),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.dangerRed,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: AppTextStyles.body2.copyWith(
                                color: AppTheme.dangerRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                const SizedBox(height: AppSpacing.xl),

                // 시작 버튼
                Obx(() {
                  return ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.setNickname,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '시작하기',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                }),

                const SizedBox(height: AppSpacing.xxl),

                // 안내 문구
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.carrotOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '게임 방법',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.carrotOrange,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow('👮', '경찰: 도둑을 잡는 역할'),
                      _buildInfoRow('🦹', '도둑: 생존하며 동료를 구출'),
                      _buildInfoRow('🏃', '영역 이탈 시 자동 체포'),
                      _buildInfoRow('🚨', '탈옥 시스템으로 부활 가능'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }
}
