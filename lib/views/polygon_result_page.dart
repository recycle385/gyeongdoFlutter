import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class PolygonResultPage extends StatelessWidget {
  final List<NLatLng> polygonCoords;

  const PolygonResultPage({super.key, required this.polygonCoords});

  @override
  Widget build(BuildContext context) {
    // 지도 초기 중심점: 다각형의 첫 좌표로 설정
    final initialPosition = polygonCoords.isNotEmpty
        ? polygonCoords.first
        : NLatLng(37.5665, 126.9780);

    return Scaffold(
      appBar: AppBar(title: const Text("Polygon 결과")),
      body: NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: initialPosition,
            zoom: 15,
          ),
          rotationGesturesEnable: false, // 회전 금지
          tiltGesturesEnable: false,     // 기울기 금지
          scrollGesturesEnable: true,    // 스크롤 가능
          zoomGesturesEnable: true,      // 줌 가능
          locationButtonEnable: true,    // 현위치 버튼
        ),
        onMapReady: (controller) async {
          debugPrint("네이버 지도 로딩 완료 - 회전 금지 상태");

          if (polygonCoords.length >= 3) {
            final polygon = NPolygonOverlay(
              id: 'result_polygon',
              coords: polygonCoords,
              color: Colors.red.withOpacity(0.3),
              outlineColor: Colors.red,
              outlineWidth: 3,
            );

            await controller.addOverlay(polygon);
          }
        },
      ),
    );
  }
}
