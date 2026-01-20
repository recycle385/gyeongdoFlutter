import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/constants.dart';

/// 로컬 저장소 서비스 (SharedPreferences)
class StorageService extends GetxService {
  late SharedPreferences _prefs;

  /// 서비스 초기화
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ==================== Getters ====================

  /// 세션 ID 가져오기
  String? get sessionId => _prefs.getString(AppConstants.storageKeySessionId);

  /// 닉네임 가져오기
  String? get nickname => _prefs.getString(AppConstants.storageKeyNickname);

  /// 방 ID 가져오기
  String? get roomId => _prefs.getString(AppConstants.storageKeyRoomId);

  /// 성별 가져오기
  String? get gender => _prefs.getString(AppConstants.storageKeyGender);

  /// 세션이 존재하는지 확인
  bool get hasSession => sessionId != null && nickname != null;

  // ==================== Setters ====================

  /// 세션 저장 (세션 ID + 닉네임)
  Future<void> saveSession(String id, String name) async {
    await _prefs.setString(AppConstants.storageKeySessionId, id);
    await _prefs.setString(AppConstants.storageKeyNickname, name);
  }

  /// 방 ID 저장
  Future<void> saveRoomId(String id) async {
    await _prefs.setString(AppConstants.storageKeyRoomId, id);
  }

  /// 닉네임 업데이트
  Future<void> updateNickname(String name) async {
    await _prefs.setString(AppConstants.storageKeyNickname, name);
  }

  /// 성별 저장
  Future<void> saveGender(String gender) async {
    await _prefs.setString(AppConstants.storageKeyGender, gender);
  }

  // ==================== Clear ====================

  /// 세션 삭제
  Future<void> clearSession() async {
    await _prefs.remove(AppConstants.storageKeySessionId);
    await _prefs.remove(AppConstants.storageKeyNickname);
  }

  /// 방 ID 삭제
  Future<void> clearRoomId() async {
    await _prefs.remove(AppConstants.storageKeyRoomId);
  }

  /// 모든 데이터 삭제
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // ==================== Debug ====================

  /// 저장된 모든 데이터 출력 (디버깅용)
  void printAll() {
    debugPrint('=== StorageService Debug ===');
    debugPrint('sessionId: $sessionId');
    debugPrint('nickname: $nickname');
    debugPrint('roomId: $roomId');
    debugPrint('===========================');
  }
}
