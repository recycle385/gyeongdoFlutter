import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../app/constants.dart';

/// REST API 통신 서비스
class ApiService extends GetxService {
  final String baseUrl = AppConstants.apiUrl;

  // HTTP 클라이언트
  final http.Client _client = http.Client();

  /// 공통 헤더
  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  // ==================== 세션 API ====================

  /// 세션 생성 (닉네임 설정)
  Future<Map<String, dynamic>> createSession(String nickname) async {
    final url = '$baseUrl/session';
    print('[API] 세션 생성 요청: $url');
    print('[API] 닉네임: $nickname');
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'nickname': nickname}),
      ).timeout(const Duration(seconds: 10));

      print('[API] 응답 상태: ${response.statusCode}');
      print('[API] 응답 본문: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('[API] 에러 발생: $e');
      throw _handleError(e);
    }
  }

  // ==================== 방 API ====================

  /// 방 생성
  Future<Map<String, dynamic>> createRoom({
    required String sessionId,
    required Map<String, dynamic> playArea,
    required Map<String, dynamic> jailLocation,
    required double jailRadius,
    required int duration,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rooms'),
        headers: _headers,
        body: jsonEncode({
          'sessionId': sessionId,
          'playArea': playArea,
          'jailLocation': jailLocation,
          'jailRadius': jailRadius,
          'duration': duration,
        }),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 방 참여 (OTP 코드로)
  Future<Map<String, dynamic>> joinRoom(String otpCode, String sessionId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rooms/join'),
        headers: _headers,
        body: jsonEncode({
          'otpCode': otpCode,
          'sessionId': sessionId,
        }),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// OTP 코드 갱신
  Future<String> refreshOTP(String roomId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rooms/$roomId/otp/refresh'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      return data['otpCode'] ?? '';
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 방 정보 조회
  Future<Map<String, dynamic>> getRoomInfo(String roomId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/rooms/$roomId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== 응답 처리 ====================

  /// HTTP 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 성공
      try {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (e) {
        return {'success': true};
      }
    } else if (response.statusCode == 400) {
      // Bad Request
      final error = _parseErrorMessage(response);
      throw Exception(error);
    } else if (response.statusCode == 404) {
      // Not Found
      throw Exception(AppConstants.errorRoomNotFound);
    } else if (response.statusCode >= 500) {
      // Server Error
      throw Exception('서버 오류가 발생했습니다. (${response.statusCode})');
    } else {
      // 기타 에러
      throw Exception('요청 실패: ${response.statusCode}');
    }
  }

  /// 에러 메시지 파싱
  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data['error'] ?? data['message'] ?? '알 수 없는 오류';
    } catch (e) {
      return '요청 실패';
    }
  }

  /// 에러 처리
  String _handleError(Object error) {
    if (error is http.ClientException) {
      return AppConstants.errorNetworkFailed;
    } else if (error is FormatException) {
      return '잘못된 응답 형식입니다.';
    } else if (error.toString().contains('TimeoutException')) {
      return '요청 시간이 초과되었습니다.';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  // ==================== Cleanup ====================

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
