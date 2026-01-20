import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

/// GPS 위치 동의 화면
class GpsConsentView extends StatefulWidget {
  const GpsConsentView({super.key});

  @override
  State<GpsConsentView> createState() => _GpsConsentViewState();
}

class _GpsConsentViewState extends State<GpsConsentView> {
  bool _isAgreed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] ?? 'create'; // 'create' or 'join'

    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 서비스 동의'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // 아이콘
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppTheme.policeBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 80,
                  color: AppTheme.policeBlue,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 제목
              Text(
                '위치 서비스 권한이 필요합니다',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // 설명
              Text(
                '당근 술래잡기는 게임 진행을 위해\n위치 정보가 필요합니다.',
                style: AppTextStyles.body1.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 약관 내용
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '위치 정보 이용 안내',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• 게임 구역 이탈 감지\n'
                      '• 감옥 근처 탈옥 기능 활성화\n'
                      '• 플레이어 간 거리 계산\n\n'
                      '위치 정보는 게임 중에만 사용되며,\n서버에 저장되지 않습니다.',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 동의 체크박스
              InkWell(
                onTap: () {
                  setState(() {
                    _isAgreed = !_isAgreed;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (value) {
                        setState(() {
                          _isAgreed = value ?? false;
                        });
                      },
                      activeColor: AppTheme.carrotOrange,
                    ),
                    Expanded(
                      child: Text(
                        '위치 서비스 이용에 동의합니다',
                        style: AppTextStyles.body1,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 다음 버튼
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAgreed && !_isLoading
                      ? () => _requestPermissionAndProceed(mode)
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('동의하고 계속하기'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissionAndProceed(String mode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 위치 권한 요청
      final status = await Permission.location.request();

      if (status.isGranted) {
        // 권한 승인됨 - 다음 화면으로 이동
        if (mode == 'create') {
          // 방 생성 플로우: 지도 구역 설정으로 이동
          Get.toNamed(Routes.CREATE_ROOM);
        } else {
          // 입장 플로우: 닉네임 입력으로 이동
          final otpCode = Get.arguments?['otpCode'];
          Get.toNamed(Routes.PLAYER_INFO, arguments: {'otpCode': otpCode});
        }
      } else if (status.isDenied) {
        // 권한 거부됨
        Get.snackbar(
          '권한 필요',
          '위치 권한이 거부되었습니다. 게임을 위해 권한이 필요합니다.',
          backgroundColor: AppTheme.warningAmber,
          colorText: Colors.white,
        );
      } else if (status.isPermanentlyDenied) {
        // 영구적으로 거부됨 - 설정으로 이동 안내
        Get.dialog(
          AlertDialog(
            title: const Text('권한 설정 필요'),
            content: const Text(
              '위치 권한이 영구적으로 거부되었습니다.\n설정에서 직접 권한을 허용해주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  openAppSettings();
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '권한 요청 중 오류가 발생했습니다.',
        backgroundColor: AppTheme.dangerRed,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
