import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 서비스 (테스트 모드 - 모든 권한 자동 허용)
class PermissionService {
  /// 카메라 권한 요청 (테스트: 항상 true 반환)
  static Future<bool> requestCameraPermission() async {
    if (kDebugMode) {
      print('🔓 테스트 모드: 카메라 권한 자동 허용');
    }
    return true; // 테스트용: 무조건 허용
  }

  /// 사진 접근 권한 요청 (테스트: 항상 true 반환)
  static Future<bool> requestPhotoPermission() async {
    if (kDebugMode) {
      print('🔓 테스트 모드: 사진 접근 권한 자동 허용');
    }
    return true; // 테스트용: 무조건 허용
  }

  /// 저장소 쓰기 권한 요청 (테스트: 항상 true 반환)
  static Future<bool> requestStoragePermission() async {
    if (kDebugMode) {
      print('🔓 테스트 모드: 저장소 권한 자동 허용');
    }
    return true; // 테스트용: 무조건 허용
  }
}
