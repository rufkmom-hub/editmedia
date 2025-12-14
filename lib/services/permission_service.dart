import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 서비스
class PermissionService {
  /// 카메라 권한 요청
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('카메라 권한 요청 실패: $e');
      }
      return false;
    }
  }

  /// 사진 접근 권한 요청 (Android 13+)
  static Future<bool> requestPhotoPermission() async {
    try {
      if (await Permission.photos.isGranted) {
        return true;
      }
      
      final status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      }
      
      // Android 12 이하는 storage 권한 사용
      if (status.isPermanentlyDenied) {
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('사진 권한 요청 실패: $e');
      }
      return false;
    }
  }

  /// 저장소 쓰기 권한 요청
  static Future<bool> requestStoragePermission() async {
    try {
      if (await Permission.photos.isGranted) {
        return true;
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('저장소 권한 요청 실패: $e');
      }
      return false;
    }
  }
}
