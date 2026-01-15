import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../utils/map_geometry_utils.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../app/routes.dart';

enum MapEditorMode { drawArea, setJail, view }

/// 지도 편집 Controller
class MapEditorController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  // 상태 변수
  final editorMode = MapEditorMode.drawArea.obs;
  final gameDuration = 1800.obs; // 초 단위 (기본 30분)
  final isCreating = false.obs;

  // 기존 상태 변수
  final isDrawing = false.obs;
  final drawingStarted = false.obs;
  final drawingDone = false.obs;
  final isEditMode = false.obs; // 내부 편집 모드 (드래그 등)
  final drawPoints = <Offset>[].obs;

  // 지도 데이터
  NaverMapController? _mapController;
  final polygonCoords = Rx<List<NLatLng>?>(null);
  NPolygonOverlay? _polygonOverlay;
  final _markers = <NMarker>[].obs;
  final jailLocation = Rx<NLatLng?>(null);
  NMarker? _jailMarker;

  // 드래그 관련
  final draggingMarkerIndex = Rx<int?>(null);
  NLatLng? _previousPosition;

  // Getters
  NaverMapController? get mapController => _mapController;
  List<NMarker> get markers => _markers;
  
  // 유효성 검사
  final isValid = false.obs;

  void setMapController(NaverMapController controller) {
    _mapController = controller;
  }

  void onMapReady(NaverMapController controller) {
    _mapController = controller;
    print("Map Ready");
  }

  void onMapTapped(NPoint point, NLatLng latLng) {
    if (editorMode.value == MapEditorMode.setJail) {
      _setJail(latLng);
    } else if (editorMode.value == MapEditorMode.drawArea) {
      // 그리기 모드에서의 탭 로직 (필요 시)
    }
  }

  void setMode(MapEditorMode mode) {
    editorMode.value = mode;
    if (mode == MapEditorMode.drawArea) {
      // 영역 설정 모드
    } else if (mode == MapEditorMode.setJail) {
      // 감옥 설정 모드
    }
  }

  Future<void> _setJail(NLatLng latLng) async {
    jailLocation.value = latLng;
    
    if (_jailMarker != null) {
      try {
        await _mapController?.deleteOverlay(_jailMarker!.info);
      } catch (_) {}
    }

    _jailMarker = NMarker(
      id: 'jail_marker',
      position: latLng,
      iconTintColor: Colors.red,
      caption: NOverlayCaption(text: '감옥'),
    );
    await _mapController?.addOverlay(_jailMarker!);
    
    _checkValidity();
  }

  void _checkValidity() {
    isValid.value = polygonCoords.value != null && 
                    polygonCoords.value!.length >= 3 &&
                    jailLocation.value != null;
  }

  Future<void> createRoom() async {
    if (!isValid.value) return;
    
    try {
      isCreating.value = true;
      
      // GeoJSON 변환 등의 로직 필요
      
      // API 호출 시뮬레이션
      // final roomId = await _api.createRoom(...);
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
      final roomId = "ROOM_${DateTime.now().millisecondsSinceEpoch}"; // 임시 ID
      
      // 로컬에 방 정보 저장
      await _storage.saveRoomId(roomId);
      
      // 대기실로 이동
      Get.offNamed(Routes.WAITING_ROOM, arguments: {'roomId': roomId});
      
    } catch (e) {
      Get.snackbar('오류', '방 생성 실패: $e');
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> clearAll() async {
    await _clearOverlays();
    if (_jailMarker != null) {
      try {
        await _mapController?.deleteOverlay(_jailMarker!.info);
      } catch (_) {}
      _jailMarker = null;
    }
    
    jailLocation.value = null;
    polygonCoords.value = null;
    isValid.value = false;
    
    resetFull(); // 기존 초기화 로직
  }

  // 1. [그리기 시작] 버튼
  void startDrawing() {
    _freezeMap();
    _prepareDrawingState();
  }

  // 2. [다시 그리기] 버튼
  Future<void> clearForRedraw() async {
    await _clearOverlays();
    _prepareDrawingState();
  }

  // 3. [위치 변경] 버튼
  Future<void> resetFull() async {
    await _clearOverlays();

    drawingStarted.value = false;
    drawingDone.value = false;
    isDrawing.value = false;
    isEditMode.value = false;
    drawPoints.clear();
    polygonCoords.value = null;
    draggingMarkerIndex.value = null;

    _mapController?.setLocationTrackingMode(NLocationTrackingMode.follow);
  }

  // 내부: 그리기 준비 상태
  void _prepareDrawingState() {
    isDrawing.value = true;
    drawingStarted.value = true;
    drawingDone.value = false;
    isEditMode.value = false;
    drawPoints.clear();
    polygonCoords.value = null;
  }

  // 내부: 오버레이 청소
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

  // 화면에 그리는 중
  void addDrawPoint(Offset point) {
    drawPoints.add(point);
  }

  // 손 뗐을 때
  Future<void> finishDrawing() async {
    if (drawPoints.length > 2) {
      if (drawPoints.first != drawPoints.last) {
        drawPoints.add(drawPoints.first);
      }
      drawingDone.value = true;
      await _convertToPolygon();
    }
  }

  // [수정] 버튼 토글
  void toggleEditMode() {
    isEditMode.value = !isEditMode.value;
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
      coords.add(latLng);
    }

    if (coords.length < 3) return;
    if (coords.first != coords.last) coords.add(coords.first);

    await _drawPolygonOnMap(coords);
    await _createEditableMarkers(coords);

    polygonCoords.value = coords;
    isDrawing.value = false;
    _checkValidity();
  }

  Future<void> _drawPolygonOnMap(List<NLatLng> coords) async {
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
  }

  // 드래그 로직
  Future<void> onDragStart(Offset localPos) async {
    if (_mapController == null || polygonCoords.value == null) return;

    for (int i = 0; i < _markers.length; i++) {
      final screenPt = await _mapController!.latLngToScreenLocation(polygonCoords.value![i]);
      final markerPos = Offset(screenPt.x, screenPt.y);
      if ((markerPos - localPos).distance < 40.0) {
        draggingMarkerIndex.value = i;
        _previousPosition = polygonCoords.value![i];
        break;
      }
    }
  }

  Future<bool> onDragUpdate(Offset localPos) async {
    if (draggingMarkerIndex.value == null || _mapController == null || polygonCoords.value == null) {
      return false;
    }

    final newLatLng = await _mapController!.screenLocationToLatLng(NPoint(localPos.dx, localPos.dy));

    if (draggingMarkerIndex.value == null || polygonCoords.value == null || newLatLng == null) {
      return false;
    }

    final i = draggingMarkerIndex.value!;

    if (_wouldCauseSelfIntersection(i, newLatLng)) {
      return true;
    }

    final coords = List<NLatLng>.from(polygonCoords.value!);
    if (i == 0) {
      coords[0] = newLatLng;
      if (coords.length > 1) coords[coords.length - 1] = newLatLng;
    } else {
      coords[i] = newLatLng;
    }

    if (i < _markers.length) _markers[i].setPosition(newLatLng);

    polygonCoords.value = coords;
    await _drawPolygonOnMap(coords);
    return false;
  }

  void onDragEnd() {
    draggingMarkerIndex.value = null;
  }

  // 중복 검사
  Map<String, dynamic>? checkOverlapOnDragEnd(int movedIndex) {
    if (polygonCoords.value == null) return null;

    final coords = polygonCoords.value!;
    final movedPoint = coords[movedIndex];
    int validPoints = coords.length - 1;

    double currentZoom = _mapController!.nowCameraPosition.zoom;

    double dynamicTolerance;
    if (currentZoom >= 18) {
      dynamicTolerance = 0.000005;
    } else if (currentZoom >= 16) {
      dynamicTolerance = 0.000015;
    } else if (currentZoom >= 14) {
      dynamicTolerance = 0.000040;
    } else {
      dynamicTolerance = 0.000100;
    }

    for (int i = 0; i < validPoints; i++) {
      int nextI = (i + 1) % validPoints;

      if (i == movedIndex || nextI == movedIndex) continue;

      final p1 = coords[i];
      final p2 = coords[nextI];

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
    int validPoints = polygonCoords.value!.length - 1;
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
    if (polygonCoords.value == null) return;
    List<NLatLng> newCoords = [];
    int validPoints = polygonCoords.value!.length - 1;
    for (int i = 0; i < validPoints; i++) {
      if (!indicesToRemove.contains(i)) newCoords.add(polygonCoords.value![i]);
    }
    if (newCoords.length < 3) return;
    if (newCoords.first != newCoords.last) newCoords.add(newCoords.first);

    polygonCoords.value = newCoords;
    await _drawPolygonOnMap(newCoords);
    await _createEditableMarkers(newCoords);
    _checkValidity();
  }

  Future<void> revertLastMove(int index) async {
    if (_previousPosition != null && polygonCoords.value != null) {
      final coords = List<NLatLng>.from(polygonCoords.value!);
      if (index == 0) {
        coords[0] = _previousPosition!;
        coords[coords.length - 1] = _previousPosition!;
      } else {
        coords[index] = _previousPosition!;
      }
      _markers[index].setPosition(_previousPosition!);
      polygonCoords.value = coords;
      await _drawPolygonOnMap(coords);
    }
  }

  bool _wouldCauseSelfIntersection(int movingIndex, NLatLng newPos) {
    if (polygonCoords.value == null) return false;
    List<NLatLng> temp = List.from(polygonCoords.value!);
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
