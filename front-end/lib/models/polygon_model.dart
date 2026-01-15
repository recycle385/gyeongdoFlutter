import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:ui';

/// 폴리곤 데이터 모델 (지도 편집용)
class PolygonModel {
  final List<NLatLng> coordinates; // 좌표 목록
  final List<Offset> screenPoints; // 화면 좌표 (그리기용)
  final double area; // 면적 (제곱미터)
  final double perimeter; // 둘레 (미터)

  PolygonModel({
    required this.coordinates,
    this.screenPoints = const [],
    this.area = 0.0,
    this.perimeter = 0.0,
  });

  // GeoJSON 형식으로 변환
  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Polygon',
      'coordinates': [
        coordinates.map((coord) => [coord.longitude, coord.latitude]).toList(),
      ],
    };
  }

  // GeoJSON에서 생성
  factory PolygonModel.fromGeoJson(Map<String, dynamic> json) {
    List<NLatLng> coords = [];
    if (json['coordinates'] != null && json['coordinates'] is List) {
      final ring = (json['coordinates'] as List)[0] as List;
      coords = ring.map((coord) {
        return NLatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();
    }
    return PolygonModel(coordinates: coords);
  }

  // CopyWith
  PolygonModel copyWith({
    List<NLatLng>? coordinates,
    List<Offset>? screenPoints,
    double? area,
    double? perimeter,
  }) {
    return PolygonModel(
      coordinates: coordinates ?? this.coordinates,
      screenPoints: screenPoints ?? this.screenPoints,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
    );
  }

  // 편의 메서드
  bool get isValid => coordinates.length >= 3;

  String get formattedArea {
    if (area < 1000) {
      return '${area.toStringAsFixed(0)} m²';
    } else if (area < 1000000) {
      return '${(area / 1000).toStringAsFixed(2)} km²';
    } else {
      return '${(area / 1000000).toStringAsFixed(2)} km²';
    }
  }

  String get formattedPerimeter {
    if (perimeter < 1000) {
      return '${perimeter.toStringAsFixed(0)} m';
    } else {
      return '${(perimeter / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  String toString() {
    return 'PolygonModel(points: ${coordinates.length}, area: $formattedArea, perimeter: $formattedPerimeter)';
  }
}
