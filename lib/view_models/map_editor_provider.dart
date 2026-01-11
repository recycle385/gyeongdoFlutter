import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../utils/map_geometry_utils.dart';

class MapEditorProvider extends ChangeNotifier {
  // 상태 변수
  bool isDrawing = false; // 현재 펜으로 긋고 있는 중인가?
  bool drawingStarted = false; // "그리기 시작" 버튼을 눌렀는가?
  bool drawingDone = false; // 도형 완성이 되었는가?
  bool isEditMode = false; // 마커 수정 모드인가?
  List<Offset> drawPoints = [];

  // 지도 데이터
  NaverMapController? _mapController;
  List<NLatLng>? polygonCoords; // 최종 변환된 좌표
  NPolygonOverlay? _polygonOverlay;
  final List<NMarker> _markers = [];

  // 드래그 관련
  int? draggingMarkerIndex;
  NLatLng? _previousPosition;

  // Getter
  NaverMapController? get mapController => _mapController;
  List<NMarker> get markers => _markers;

  void setMapController(NaverMapController controller) {
    _mapController = controller;
  }

  // 1. [그리기 시작] 버튼
  void startDrawing() {
    _freezeMap(); // 지도 고정
    _prepareDrawingState();
    notifyListeners();
  }

  // 2. [다시 그리기] 버튼 로직 (지도 회전/위치는 유지하고, 선만 지움)
  Future<void> clearForRedraw() async {
    await _clearOverlays(); // 기존 도형/마커 삭제
    _prepareDrawingState(); // 그리기 대기 상태로 진입
    notifyListeners();
  }

  // 3. [위치 변경] 버튼 로직 (완전 초기화)
  Future<void> resetFull() async {
    await _clearOverlays();

    // 상태 완전 초기화
    drawingStarted = false;
    drawingDone = false;
    isDrawing = false;
    isEditMode = false;
    drawPoints.clear();
    polygonCoords = null;
    draggingMarkerIndex = null;

    // 지도 고정 풀기 (위치 이동 가능하게)
    _mapController?.setLocationTrackingMode(NLocationTrackingMode.follow);

    notifyListeners();
  }

  // 내부 함수: 그리기 준비 상태로 세팅
  void _prepareDrawingState() {
    isDrawing = true;
    drawingStarted = true;
    drawingDone = false;
    isEditMode = false;
    drawPoints.clear();
    polygonCoords = null;
  }

  // 내부 함수: 오버레이 청소
  Future<void> _clearOverlays() async {
    if (_polygonOverlay != null) {
      try {
        await _mapController?.deleteOverlay(_polygonOverlay!.info);
      } catch (_) {}
      _polygonOverlay = null;
    }
    for (var m in _markers) {
      try {
        await _mapController?.deleteOverlay(m.info);
      } catch (_) {}
    }
    _markers.clear();
  }

  // 화면에 그리는 중 (PanUpdate)
  void addDrawPoint(Offset point) {
    drawPoints.add(point);
    notifyListeners();
  }

  // 손 뗐을 때 (PanEnd) -> 폴리곤 변환
  Future<void> finishDrawing() async {
    if (drawPoints.length > 2) {
      if (drawPoints.first != drawPoints.last) {
        drawPoints.add(drawPoints.first);
      }
      drawingDone = true; // 그리기 완료됨
      notifyListeners();
      await _convertToPolygon();
    }
  }

  // [수정] 버튼 토글
  void toggleEditMode() {
    isEditMode = !isEditMode;
    notifyListeners();
  }

  // 지도 얼리기
  void _freezeMap() {
    _mapController?.setLocationTrackingMode(NLocationTrackingMode.none);
  }

  // 다각형 변환 및 마커 생성
  Future<void> _convertToPolygon() async {
    if (_mapController == null || drawPoints.isEmpty) return;

    List<Offset> simplified = MapGeometryUtils.simplifyPoints(drawPoints, epsilon: 5.0);

    List<NLatLng> coords = [];
    for (var point in simplified) {
      final latLng = await _mapController!.screenLocationToLatLng(NPoint(point.dx, point.dy));
      if (latLng != null) coords.add(latLng);
    }

    if (coords.length < 3) return;
    if (coords.first != coords.last) coords.add(coords.first);

    await _drawPolygonOnMap(coords);
    await _createEditableMarkers(coords);

    polygonCoords = coords;
    isDrawing = false; // 더 이상 펜으로 그리는 상태 아님
    notifyListeners();
  }

  Future<void> _drawPolygonOnMap(List<NLatLng> coords) async {
    // 기존 것 삭제 후 재생성
    if (_polygonOverlay != null) {
      try {
        await _mapController?.deleteOverlay(_polygonOverlay!.info);
      } catch (_) {}
    }

    _polygonOverlay = NPolygonOverlay(
      id: 'drawn_polygon',
      coords: coords,
      color: Colors.red.withOpacity(0.3),
      outlineColor: Colors.red,
      outlineWidth: 3,
    );
    await _mapController?.addOverlay(_polygonOverlay!);
  }

  Future<void> _createEditableMarkers(List<NLatLng> coords) async {
    // 기존 마커 삭제
    for (var m in _markers) {
      try {
        await _mapController?.deleteOverlay(m.info);
      } catch (_) {}
    }
    _markers.clear();

    int count = (coords.first == coords.last) ? coords.length - 1 : coords.length;
    for (int i = 0; i < count; i++) {
      final marker = NMarker(id: 'marker_$i', position: coords[i]);
      await _mapController?.addOverlay(marker);
      _markers.add(marker);
    }
    notifyListeners();
  }

  // --- 드래그 로직 (기존과 동일) ---
  Future<void> onDragStart(Offset localPos) async {
    if (_mapController == null || polygonCoords == null) return;

    for (int i = 0; i < _markers.length; i++) {
      final screenPt = await _mapController!.latLngToScreenLocation(polygonCoords![i]);
      final markerPos = Offset(screenPt.x, screenPt.y);
      if ((markerPos - localPos).distance < 40.0) {
        draggingMarkerIndex = i;
        _previousPosition = polygonCoords![i];
        notifyListeners();
        break;
      }
    }
  }

  // 🆕 드래그 업데이트 로직 (수정됨: 비동기 충돌 방지)
  Future<bool> onDragUpdate(Offset localPos) async {
    // 1. 시작 전 체크
    if (draggingMarkerIndex == null || _mapController == null || polygonCoords == null) return false;

    // 2. 비동기 작업 (여기서 시간이 걸림)
    final newLatLng = await _mapController!.screenLocationToLatLng(NPoint(localPos.dx, localPos.dy));

    // ============================================================
    // 🔥 [핵심 수정] 비동기(await) 작업이 끝난 후,
    // 그 사이에 드래그가 끝났거나 취소되지 않았는지 다시 확인해야 함!
    // ============================================================
    if (draggingMarkerIndex == null || polygonCoords == null || newLatLng == null) {
      return false;
    }

    // 3. 안전하게 강제 언래핑 (!) 사용
    final i = draggingMarkerIndex!;

    // 꼬임 감지
    if (_wouldCauseSelfIntersection(i, newLatLng)) {
      return true; // 경고 필요함
    }

    // 좌표 업데이트
    if (i == 0) {
      polygonCoords![0] = newLatLng;
      if (polygonCoords!.length > 1) polygonCoords![polygonCoords!.length - 1] = newLatLng;
    } else {
      polygonCoords![i] = newLatLng;
    }

    if (i < _markers.length) _markers[i].setPosition(newLatLng);

    await _drawPolygonOnMap(polygonCoords!); // 폴리곤 갱신
    return false;
  }

  void onDragEnd() {
    draggingMarkerIndex = null;
    notifyListeners();
  }

  // --- 중복 검사 로직 (기존과 동일) ---
  Map<String, dynamic>? checkOverlapOnDragEnd(int movedIndex) {
    if (polygonCoords == null) return null;

    final movedPoint = polygonCoords![movedIndex];
    int validPoints = polygonCoords!.length - 1;

    double currentZoom = _mapController!.nowCameraPosition.zoom;

    double dynamicTolerance;
    if (currentZoom >= 18) {
      dynamicTolerance = 0.000005; // 초고밀도 확대 시 (약 1.5m)
    } else if (currentZoom >= 16) {
      dynamicTolerance = 0.000015; // 일반 (약 5m - 기존값)
    } else if (currentZoom >= 14) {
      dynamicTolerance = 0.000040; // 약간 멀 때 (약 12m)
    } else {
      dynamicTolerance = 0.000100; // 멀리서 볼 때 (약 30m)
    }

    for (int i = 0; i < validPoints; i++) {
      int nextI = (i + 1) % validPoints;

      // ✅ [수정 완료] 자기 자신과 직접 연결된 선분 2개만 제외
      if (i == movedIndex || nextI == movedIndex) continue;

      final p1 = polygonCoords![i];
      final p2 = polygonCoords![nextI];

      // 거리 기반 정밀 검사
      double distance = MapGeometryUtils.getDistanceFromLine(movedPoint, p1, p2);

      if (distance < dynamicTolerance && MapGeometryUtils.isPointBetween(movedPoint, p1, p2)) {
        List<int> opt1 = _findPointsToRemove(movedIndex, i, nextI, clockwise: true);
        List<int> opt2 = _findPointsToRemove(movedIndex, i, nextI, clockwise: false);

        if (opt1.isNotEmpty || opt2.isNotEmpty) {
          return {
            'movedIndex': movedIndex,
            'option1': opt1,
            'option2': opt2,
          };
        }
      }
    }
    return null;
  }

  List<int> _findPointsToRemove(int movedIndex, int start, int end, {required bool clockwise}) {
    List<int> remove = [];
    int validPoints = polygonCoords!.length - 1;
    if (clockwise) {
      int curr = (movedIndex + 1) % validPoints;
      while (curr != end) {
        remove.add(curr);
        curr = (curr + 1) % validPoints;
        if (remove.length > validPoints) break;
      }
    } else {
      int curr = (movedIndex - 1 + validPoints) % validPoints;
      while (curr != start) {
        remove.add(curr);
        curr = (curr - 1 + validPoints) % validPoints;
        if (remove.length > validPoints) break;
      }
    }
    return remove;
  }

  Future<void> removePoints(List<int> indicesToRemove) async {
    if (polygonCoords == null) return;
    List<NLatLng> newCoords = [];
    int validPoints = polygonCoords!.length - 1;
    for (int i = 0; i < validPoints; i++) {
      if (!indicesToRemove.contains(i)) newCoords.add(polygonCoords![i]);
    }
    if (newCoords.length < 3) return;
    if (newCoords.first != newCoords.last) newCoords.add(newCoords.first);

    polygonCoords = newCoords;
    await _drawPolygonOnMap(newCoords);
    await _createEditableMarkers(newCoords);
  }

  Future<void> revertLastMove(int index) async {
    if (_previousPosition != null && polygonCoords != null) {
      if (index == 0) {
        polygonCoords![0] = _previousPosition!;
        polygonCoords![polygonCoords!.length - 1] = _previousPosition!;
      } else {
        polygonCoords![index] = _previousPosition!;
      }
      _markers[index].setPosition(_previousPosition!);
      await _drawPolygonOnMap(polygonCoords!);
    }
  }

  bool _wouldCauseSelfIntersection(int movingIndex, NLatLng newPos) {
    if (polygonCoords == null) return false;
    List<NLatLng> temp = List.from(polygonCoords!);
    if (movingIndex == 0) {
      temp[0] = newPos;
      temp[temp.length - 1] = newPos;
    } else {
      temp[movingIndex] = newPos;
    }
    int validSegs = temp.length - 1;
    for (int i = 0; i < validSegs; i++) {
      int nextI = (i + 1) % validSegs;
      for (int j = i + 2; j < validSegs; j++) {
        int nextJ = (j + 1) % validSegs;
        if (nextI == j || nextJ == i) continue;
        if (MapGeometryUtils.doSegmentsIntersect(temp[i], temp[nextI], temp[j], temp[nextJ])) {
          return true;
        }
      }
    }
    return false;
  }
}