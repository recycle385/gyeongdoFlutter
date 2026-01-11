import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../view_models/map_editor_provider.dart';
import 'common_widgets/map_drawing_painter.dart';
import 'common_widgets/map_warning_dialog.dart';
import 'polygon_result_page.dart';

class MapTestView extends StatelessWidget {
  const MapTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapEditorProvider(),
      child: const _MapTestBody(),
    );
  }
}

class _MapTestBody extends StatefulWidget {
  const _MapTestBody();

  @override
  State<_MapTestBody> createState() => _MapTestBodyState();
}

class _MapTestBodyState extends State<_MapTestBody> {
  Future<void>? _lastDragFuture;

  @override
  Widget build(BuildContext context) {
    // watch로 상태 감지
    final provider = context.watch<MapEditorProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. 지도 위젯
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780),
                zoom: 15,
              ),
              locationButtonEnable: true,
              rotationGesturesEnable: true,
            ),
            onMapReady: (controller) {
              context.read<MapEditorProvider>().setMapController(controller);
            },
          ),

          // 2. 그리기 영역 (그리기 모드일 때만 활성)
          if (provider.isDrawing && !provider.drawingDone)
            GestureDetector(
              onPanUpdate: (details) {
                context.read<MapEditorProvider>().addDrawPoint(details.localPosition);
              },
              onPanEnd: (_) {
                context.read<MapEditorProvider>().finishDrawing();
              },
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: MapDrawingPainter(points: provider.drawPoints),
              ),
            ),

          // 3. 편집 모드 터치 영역 (수정 버튼 눌렀을 때만 활성)
          if (provider.isEditMode && provider.drawingDone)
            GestureDetector(
              onPanStart: (details) {
                context.read<MapEditorProvider>().onDragStart(details.localPosition);
              },
              onPanUpdate: (details) {
                // 🔥 [수정] await를 사용하지 않고 Future를 저장해둠
                final future = context.read<MapEditorProvider>().onDragUpdate(details.localPosition);
                _lastDragFuture = future;

                // 햅틱 반응은 별도로 처리
                future.then((hasWarning) {
                  if (hasWarning && mounted) HapticFeedback.lightImpact();
                });
              },
              onPanEnd: (_) async {
                // 🔥 [핵심] 마지막 업데이트가 끝날 때까지 기다림
                if (_lastDragFuture != null) {
                  await _lastDragFuture;
                  _lastDragFuture = null;
                }

                if (!mounted) return;
                final p = context.read<MapEditorProvider>();

                // 드래그가 끝난 마커 인덱스 가져오기
                final movedIdx = p.draggingMarkerIndex;

                p.onDragEnd(); // 드래그 종료 상태 업데이트

                // 🔥 중복 검사 실행
                if (movedIdx != null) {
                  // 디버깅용 로그 추가
                  debugPrint("중복 검사 시작: marker $movedIdx");

                  final overlapInfo = p.checkOverlapOnDragEnd(movedIdx);

                  if (overlapInfo != null) {
                    debugPrint("중복 발견! 다이얼로그 표시");
                    await _showOverlapDialog(context, overlapInfo);
                  } else {
                    debugPrint("중복 없음");
                  }
                }
              },
              child: Container(color: Colors.transparent),
            ),

          // 4. 하단 버튼 컨트롤러
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: provider.drawingStarted
                  ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // [위치변경]: 아예 처음으로 (지도 이동 가능하게 풀림)
                    ElevatedButton(
                      onPressed: provider.drawingDone && !provider.isEditMode
                          ? () => context.read<MapEditorProvider>().resetFull()
                          : null,
                      child: const Text("위치변경"),
                    ),
                    const SizedBox(width: 8),

                    // [다시그리기]: 지도는 유지하고 선만 지움
                    ElevatedButton(
                      onPressed: provider.drawingDone && !provider.isEditMode
                          ? () => context.read<MapEditorProvider>().clearForRedraw()
                          : null,
                      child: const Text("다시그리기"),
                    ),
                    const SizedBox(width: 8),

                    // [수정]: 편집 모드 토글
                    ElevatedButton(
                      onPressed: provider.drawingDone
                          ? () => context.read<MapEditorProvider>().toggleEditMode()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isEditMode ? Colors.orange : null,
                      ),
                      child: Text(provider.isEditMode ? "수정완료" : "수정"),
                    ),
                    const SizedBox(width: 8),

                    // [완료]: 다음 페이지로
                    ElevatedButton(
                      onPressed: provider.drawingDone && !provider.isEditMode
                          ? () => _completeDrawing(context)
                          : null,
                      child: const Text("완료"),
                    ),
                  ],
                ),
              )
                  : ElevatedButton(
                onPressed: () => context.read<MapEditorProvider>().startDrawing(),
                child: const Text("그리기 시작"),
              ),
            ),
          ),

          // 5. 편집 가이드 메세지
          if (provider.isEditMode)
            Positioned(
              top: 50, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    provider.draggingMarkerIndex != null
                        ? "📍 마커 드래그 중..."
                        : "🔧 마커를 드래그하여 수정하세요",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showOverlapDialog(BuildContext context, Map<String, dynamic> info) async {
    final provider = context.read<MapEditorProvider>();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MapWarningDialog(
        option1: info['option1'],
        option2: info['option2'],
        fullCoords: provider.polygonCoords ?? [],
      ),
    );

    if (result == 'option1') {
      await provider.removePoints(info['option1']);
    } else if (result == 'option2') {
      await provider.removePoints(info['option2']);
    } else {
      await provider.revertLastMove(info['movedIndex']);
    }
  }

  void _completeDrawing(BuildContext context) {
    final provider = context.read<MapEditorProvider>();
    if (provider.polygonCoords != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PolygonResultPage(polygonCoords: provider.polygonCoords!),
        ),
      );
    }
  }
}