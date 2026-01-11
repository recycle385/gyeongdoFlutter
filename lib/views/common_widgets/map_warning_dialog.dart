import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapWarningDialog extends StatelessWidget {
  final List<int> option1;
  final List<int> option2;
  final List<NLatLng> fullCoords;

  const MapWarningDialog({
    super.key,
    required this.option1,
    required this.option2,
    required this.fullCoords,
  });

  @override
  Widget build(BuildContext context) {
    // [추가됨] 옵션1은 없고 옵션2만 유효한지 확인
    final bool isOnlyOption2 = option1.isEmpty && option2.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '중복된 선 감지',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.of(context).pop('cancel'),
                  ),
                ],
              ),
            ),

            // 설명
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '유지할 구역을 선택하세요',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),

            // 옵션 선택 카드들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 옵션 1 (기존과 동일 - 파랑)
                  _buildCard(context, 'option1', '🔵 옵션 A', Colors.blue, option1),

                  if (option1.isNotEmpty && option2.isNotEmpty) const SizedBox(width: 16),

                  // [수정됨] 옵션 2: 단독일 경우 파란색 스타일 적용
                  _buildCard(
                      context,
                      'option2',
                      isOnlyOption2 ? '🔵 옵션 A' : '🟠 옵션 B', // 단독이면 A로 표시
                      isOnlyOption2 ? Colors.blue : Colors.orange, // 단독이면 파란색
                      option2
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 미니맵 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPreviewMap(isOnlyOption2), // [수정] 플래그 전달
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _buildCard는 기존과 동일 ...
  Widget _buildCard(BuildContext context, String value, String title, Color color, List<int> option) {
    if (option.isEmpty) return const SizedBox();
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value), // 값은 그대로 'option2' 반환
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 3),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Text('제거: ${option.length}개', style: TextStyle(color: color.withOpacity(0.8))),
              Text('남음: ${fullCoords.length - 1 - option.length}개', style: TextStyle(color: color.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewMap(bool isOnlyOption2) { // [수정] 매개변수 추가
    if (fullCoords.isEmpty) return const Center(child: Text('지도 로딩 실패'));

    // ... (bounds 계산 로직 기존과 동일) ...
    double minLat = fullCoords.first.latitude;
    double maxLat = fullCoords.first.latitude;
    double minLng = fullCoords.first.longitude;
    double maxLng = fullCoords.first.longitude;

    for (var p in fullCoords) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = NLatLngBounds(
      southWest: NLatLng(minLat, minLng),
      northEast: NLatLng(maxLat, maxLng),
    );

    return NaverMap(
      options: const NaverMapViewOptions(
        scrollGesturesEnable: false,
        zoomGesturesEnable: false,
        tiltGesturesEnable: false,
        rotationGesturesEnable: false,
        locationButtonEnable: false,
        liteModeEnable: true,
      ),
      onMapReady: (controller) async {
        final cameraUpdate = NCameraUpdate.fitBounds(
          bounds,
          padding: const EdgeInsets.all(40),
        );
        await controller.updateCamera(cameraUpdate);

        // [수정됨] 옵션2의 색상을 상황에 따라 결정
        Color color2 = isOnlyOption2 ? Colors.blue : Colors.orange;

        await _drawPreviewPolygon(controller, option1, Colors.blue, 'preview_A');
        await _drawPreviewPolygon(controller, option2, color2, 'preview_B');
      },
    );
  }

  // ... _drawPreviewPolygon 기존과 동일 ...
  Future<void> _drawPreviewPolygon(NaverMapController controller, List<int> removeIndices, Color color, String id) async {
    if (removeIndices.isEmpty) return;

    List<NLatLng> coords = [];
    int validPoints = fullCoords.length - 1;

    for (int i = 0; i < validPoints; i++) {
      if (!removeIndices.contains(i)) coords.add(fullCoords[i]);
    }

    if (coords.length >= 3) {
      if (coords.first != coords.last) coords.add(coords.first);

      final polygon = NPolygonOverlay(
        id: id,
        coords: coords,
        color: color.withOpacity(0.5),
        outlineColor: color,
        outlineWidth: 5,
      );
      await controller.addOverlay(polygon);
    }
  }
}