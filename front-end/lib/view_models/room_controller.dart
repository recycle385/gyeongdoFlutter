import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../app/constants.dart';
import '../app/routes.dart';

/// 방 Controller (방 생성, OTP 참여, 대기실 관리)
class RoomController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  // OTP 입력
  final otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // 임시 저장된 OTP 코드 (플로우 진행 중 사용)
  final pendingOtpCode = ''.obs;

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  /// OTP 검증
  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP 코드를 입력해주세요';
    }
    if (!AppConstants.otpRegex.hasMatch(value)) {
      return AppConstants.errorInvalidOtp;
    }
    return null;
  }

  /// OTP 검증 후 GPS 동의 화면으로 이동 (새 플로우)
  Future<void> joinRoomWithOtp() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final otpCode = otpController.text.trim();

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // OTP 코드 임시 저장
      pendingOtpCode.value = otpCode;

      // GPS 동의 화면으로 이동 (mode: join, otpCode 전달)
      Get.toNamed(
        Routes.GPS_CONSENT,
        arguments: {
          'mode': 'join',
          'otpCode': otpCode,
        },
      );
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        '오류',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 실제 방 참여 (세션 생성 후 호출)
  Future<bool> joinRoomAfterSession(String otpCode, String sessionId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // API 호출
      final response = await _api.joinRoom(otpCode, sessionId);

      final roomId = response['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw Exception('방 ID를 받지 못했습니다.');
      }

      // 방 ID 저장
      await _storage.saveRoomId(roomId);

      Get.snackbar(
        '성공',
        AppConstants.successRoomJoined,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        '오류',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// OTP 코드 클리어
  void clearOtpCode() {
    otpController.clear();
    pendingOtpCode.value = '';
    errorMessage.value = '';
  }
}
