import 'dart:ui';
import 'dart:math';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapGeometryUtils {
  /// Douglas-Peucker 알고리즘 (선 단순화)
  static List<Offset> simplifyPoints(List<Offset> points, {required double epsilon}) {
    if (points.length <= 2) return points;

    double maxDistance = 0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = perpendicularDistance(points[i], points.first, points.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      List<Offset> left = simplifyPoints(points.sublist(0, index + 1), epsilon: epsilon);
      List<Offset> right = simplifyPoints(points.sublist(index), epsilon: epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// 점과 선 사이의 수직 거리 계산
  static double perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    double dx = lineEnd.dx - lineStart.dx;
    double dy = lineEnd.dy - lineStart.dy;

    double mag = dx * dx + dy * dy;
    if (mag == 0) return (point - lineStart).distance;

    double u = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / mag;

    Offset intersection;
    if (u < 0) {
      intersection = lineStart;
    } else if (u > 1) {
      intersection = lineEnd;
    } else {
      intersection = Offset(lineStart.dx + u * dx, lineStart.dy + u * dy);
    }

    return (point - intersection).distance;
  }

  static double getDistanceFromLine(NLatLng point, NLatLng start, NLatLng end) {
    double x0 = point.longitude;
    double y0 = point.latitude;
    double x1 = start.longitude;
    double y1 = start.latitude;
    double x2 = end.longitude;
    double y2 = end.latitude;

    // 분자: |(x2-x1)(y1-y0) - (x1-x0)(y2-y1)|  (외적의 크기)
    double numerator = ((x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)).abs();

    // 분모: sqrt((x2-x1)^2 + (y2-y1)^2) (선분의 길이)
    double denominator = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));

    if (denominator == 0) return 0; // 점이 겹친 경우

    return numerator / denominator;
  }

  /// 두 선분이 교차하는지 확인 (CCW 알고리즘)
  static bool doSegmentsIntersect(NLatLng a1, NLatLng a2, NLatLng b1, NLatLng b2) {
    double ccw(NLatLng a, NLatLng b, NLatLng c) {
      return (c.latitude - a.latitude) * (b.longitude - a.longitude) -
          (b.latitude - a.latitude) * (c.longitude - a.longitude);
    }

    double ccw1 = ccw(a1, a2, b1);
    double ccw2 = ccw(a1, a2, b2);
    double ccw3 = ccw(b1, b2, a1);
    double ccw4 = ccw(b1, b2, a2);

    // 선분이 교차하려면 서로 반대편에 있어야 함
    if (ccw1 * ccw2 < 0 && ccw3 * ccw4 < 0) {
      return true;
    }
    return false;
  }

  /// 점이 두 점(Box) 사이에 있는지 확인
  static bool isPointBetween(NLatLng point, NLatLng start, NLatLng end) {
    double minLat = min(start.latitude, end.latitude);
    double maxLat = max(start.latitude, end.latitude);
    double minLng = min(start.longitude, end.longitude);
    double maxLng = max(start.longitude, end.longitude);

    // 🔥 약간의 오차(buffer)를 둬서 터치 미스 보정
    const double buffer = 0.0001;

    return point.latitude >= minLat - buffer && point.latitude <= maxLat + buffer &&
        point.longitude >= minLng - buffer && point.longitude <= maxLng + buffer;
  }

  // 🔥 [새로 추가됨] 두 선분 (p1-p2)와 (p3-p4)의 교차점 좌표를 반환 (없으면 null)
  static NLatLng? getIntersectionPoint(NLatLng p1, NLatLng p2, NLatLng p3, NLatLng p4) {
    double x1 = p1.longitude, y1 = p1.latitude;
    double x2 = p2.longitude, y2 = p2.latitude;
    double x3 = p3.longitude, y3 = p3.latitude;
    double x4 = p4.longitude, y4 = p4.latitude;

    double denominator = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);

    // 평행하면 교차 안 함
    if (denominator == 0) return null;

    double ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denominator;
    double ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denominator;

    // 선분 내부에서 교차하는지 확인 (0~1 사이)
    const double eps = 1e-9; // 부동소수점 오차 보정
    if (ua >= -eps && ua <= 1.0 + eps && ub >= -eps && ub <= 1.0 + eps) {
      double intersectX = x1 + ua * (x2 - x1);
      double intersectY = y1 + ua * (y2 - y1);
      return NLatLng(intersectY, intersectX);
    }

    return null;
  }

  static double calculatePolygonArea(List<NLatLng> coords) {
    if (coords.length < 3) return 0.0;

    double area = 0.0;
    // 기준점 (첫번째 좌표)
    final center = coords.first;
    const double metersPerLat = 111000; // 위도 1도당 약 111km
    // 경도 1도당 길이는 위도에 따라 다름 (cos 이용)
    final double metersPerLng = 111000 * cos(center.latitude * pi / 180);

    for (int i = 0; i < coords.length; i++) {
      final p1 = coords[i];
      final p2 = coords[(i + 1) % coords.length]; // 마지막 점과 첫 점 연결

      // 기준점 상대 좌표로 변환 (미터 단위)
      double x1 = (p1.longitude - center.longitude) * metersPerLng;
      double y1 = (p1.latitude - center.latitude) * metersPerLat;
      double x2 = (p2.longitude - center.longitude) * metersPerLng;
      double y2 = (p2.latitude - center.latitude) * metersPerLat;

      // 외적 합산 (신발끈 공식)
      area += (x1 * y2) - (x2 * y1);
    }

    return (area / 2.0).abs();
  }

  static double calculatePerimeter(List<NLatLng> coords) {
    if (coords.length < 2) return 0.0;

    double perimeter = 0.0;
    const double R = 6371000; // 지구 반지름 (미터)

    for (int i = 0; i < coords.length; i++) {
      final p1 = coords[i];
      final p2 = coords[(i + 1) % coords.length]; // 마지막 점과 첫 점 연결

      // 하버사인 공식 등으로 두 점 사이 거리 구하기 (간략 버전)
      double dLat = (p2.latitude - p1.latitude) * (pi / 180.0);
      double dLng = (p2.longitude - p1.longitude) * (pi / 180.0);
      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(p1.latitude * (pi / 180.0)) *
              cos(p2.latitude * (pi / 180.0)) *
              sin(dLng / 2) *
              sin(dLng / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      double distance = R * c;

      perimeter += distance;
    }
    return perimeter;
  }
}