import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../view_models/room_controller.dart';
import '../../app/theme.dart';

/// OTP 입력으로 방 참여 화면
class JoinRoomView extends GetView<RoomController> {
  const JoinRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방 참여하기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 안내 아이콘
                Icon(
                  Icons.vpn_key,
                  size: 80,
                  color: AppTheme.policeBlue,
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  'OTP 코드 입력',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  '방장에게 받은 4자리 코드를 입력하세요',
                  style: AppTextStyles.body2.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // OTP 입력 필드
                TextFormField(
                  controller: controller.otpController,
                  validator: controller.validateOtp,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.otpCode,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: '0000',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => controller.joinRoomWithOtp(),
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

                // 참여 버튼
                Obx(() {
                  return ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.joinRoomWithOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: AppTheme.policeBlue,
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
                            '참여하기',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                }),

                const SizedBox(height: AppSpacing.xxl),

                // 안내
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.policeBlue,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'OTP 코드 안내',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.policeBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '• OTP 코드는 4자리 숫자입니다\n'
                        '• 30초마다 자동으로 갱신됩니다\n'
                        '• 방장에게 최신 코드를 확인하세요',
                        style: AppTextStyles.body2,
                      ),
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
}
