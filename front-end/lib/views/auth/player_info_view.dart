import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../app/constants.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';

/// 플레이어 정보 입력 화면 (닉네임, 성별)
class PlayerInfoView extends StatefulWidget {
  const PlayerInfoView({super.key});

  @override
  State<PlayerInfoView> createState() => _PlayerInfoViewState();
}

class _PlayerInfoViewState extends State<PlayerInfoView> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정보 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // 제목
                Text(
                  '게임에서 사용할\n정보를 입력해주세요',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // 닉네임 입력
                Text(
                  '닉네임',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    hintText: '2-10자 한글, 영문, 숫자',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (!AppConstants.nicknameRegex.hasMatch(value)) {
                      return '2-10자의 한글, 영문, 숫자만 가능합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // 성별 선택
                Text(
                  '성별',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderButton(
                        label: '남성',
                        value: 'male',
                        icon: Icons.male,
                        color: AppTheme.policeBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildGenderButton(
                        label: '여성',
                        value: 'female',
                        icon: Icons.female,
                        color: AppTheme.thiefRed,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // 입장 버튼
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAndJoin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('대기실 입장'),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGender == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                color: isSelected ? color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAndJoin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      Get.snackbar(
        '성별 선택',
        '성별을 선택해주세요',
        backgroundColor: AppTheme.warningAmber,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Get.find<StorageService>();
      final api = Get.find<ApiService>();
      final nickname = _nicknameController.text.trim();
      final otpCode = Get.arguments?['otpCode'] as String?;

      if (otpCode == null || otpCode.isEmpty) {
        throw Exception('참여 코드가 없습니다. 다시 시도해주세요.');
      }

      // 1. 세션 생성
      final sessionResponse = await api.createSession(nickname);
      final sessionId = sessionResponse['sessionId'] as String;

      // 2. 로컬에 저장
      await storage.saveSession(sessionId, nickname);
      await storage.saveGender(_selectedGender!);

      // 3. 방 참여 (OTP + 세션 ID)
      final joinResponse = await api.joinRoom(otpCode, sessionId);
      final roomId = joinResponse['roomId'] as String?;

      if (roomId == null || roomId.isEmpty) {
        throw Exception('방 ID를 받지 못했습니다.');
      }

      // 4. 방 ID 저장
      await storage.saveRoomId(roomId);

      // 5. 대기실로 이동
      Get.offAllNamed(Routes.WAITING_ROOM, arguments: {'roomId': roomId});

      Get.snackbar(
        '성공',
        AppConstants.successRoomJoined,
        backgroundColor: AppTheme.aliveGreen,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        e.toString().replaceAll('Exception: ', ''),
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
