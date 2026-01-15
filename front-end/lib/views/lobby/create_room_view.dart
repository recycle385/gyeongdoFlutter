import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../view_models/map_editor_controller.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';

class CreateRoomView extends GetView<MapEditorController> {
  const CreateRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방 만들기'),
        actions: [
          TextButton(
            onPressed: controller.clearAll,
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 지도
          GetBuilder<MapEditorController>(
            builder: (controller) {
              return NaverMap(
                options: const NaverMapViewOptions(
                  locationButtonEnable: true,
                  consumeSymbolTapEvents: false,
                ),
                onMapReady: controller.onMapReady,
                onMapTapped: controller.onMapTapped,
                onCameraChange: (reason, animated) {
                  // 카메라 이동 처리
                },
              );
            },
          ),

          // 상단 안내 메시지
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Obx(() {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getInstructionText(controller.editorMode.value),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2,
                ),
              );
            }),
          ),

          // 하단 컨트롤 패널
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 모드 선택
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => _buildModeButton(
                          MapEditorMode.drawArea,
                          '활동 구역 설정',
                          Icons.pentagon_outlined,
                        )),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Obx(() => _buildModeButton(
                          MapEditorMode.setJail,
                          '감옥 설정',
                          Icons.lock_outline,
                        )),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),

                  // 게임 시간 설정
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.grey),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('게임 시간'),
                      const Spacer(),
                      Obx(() => DropdownButton<int>(
                        value: controller.gameDuration.value,
                        underline: Container(),
                        items: [10, 20, 30, 40, 50, 60].map((min) {
                          return DropdownMenuItem(
                            value: min * 60,
                            child: Text('$min분'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) controller.gameDuration.value = val;
                        },
                      )),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isValid.value ? controller.createRoom : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.carrotOrange,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: controller.isCreating.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('방 만들기 완료', style: TextStyle(fontSize: 16)),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(MapEditorMode mode, String label, IconData icon) {
    final isSelected = controller.editorMode.value == mode;
    final color = isSelected ? AppTheme.carrotOrange : Colors.grey;

    return InkWell(
      onTap: () => controller.setMode(mode),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.carrotOrange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructionText(MapEditorMode mode) {
    switch (mode) {
      case MapEditorMode.drawArea:
        return '지도에 점을 찍어 술래잡기 구역을 만들어주세요.\n(최소 3개 이상의 점이 필요합니다)';
      case MapEditorMode.setJail:
        return '도둑이 갇힐 감옥 위치를 선택해주세요.';
      case MapEditorMode.view:
        return '설정이 완료되었습니다. 방을 생성해보세요!';
    }
  }
}
