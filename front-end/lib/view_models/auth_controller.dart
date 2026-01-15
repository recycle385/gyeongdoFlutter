import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../app/constants.dart';

/// 인증 Controller (닉네임 설정, 세션 관리)
class AuthController extends GetxController {
  // Services
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  // Form
  final nicknameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  @override
  void onClose() {
    nicknameController.dispose();
    super.onClose();
  }

  /// 기존 세션 확인
  Future<void> _checkExistingSession() async {
    if (_storage.hasSession) {
      // 기존 세션이 있으면 닉네임 입력란에 표시
      nicknameController.text = _storage.nickname ?? '';
    }
  }

  /// 닉네임 검증
  String? validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    if (!AppConstants.nicknameRegex.hasMatch(value)) {
      return AppConstants.errorInvalidNickname;
    }
    return null;
  }

  /// 닉네임 설정 및 세션 생성
  Future<void> setNickname() async {
    // 유효성 검사
    if (!formKey.currentState!.validate()) {
      return;
    }

    final nickname = nicknameController.text.trim();

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // API 호출 - 세션 생성
      final response = await _api.createSession(nickname);

      final sessionId = response['sessionId'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('세션 ID를 받지 못했습니다.');
      }

      // 로컬 저장
      await _storage.saveSession(sessionId, nickname);

      // 로비 화면으로 이동
      Get.offAllNamed('/lobby');

      // 성공 메시지
      Get.snackbar(
        '환영합니다!',
        '$nickname님, 당근 술래잡기에 오신 것을 환영합니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
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

  /// 닉네임 변경 (추후 구현)
  Future<void> updateNickname(String newNickname) async {
    try {
      await _storage.updateNickname(newNickname);
      Get.snackbar(
        '완료',
        '닉네임이 변경되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '닉네임 변경에 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    await _storage.clearAll();
    Get.offAllNamed('/');
    Get.snackbar(
      '로그아웃',
      '로그아웃되었습니다.',
      backgroundColor: Colors.grey[700],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
