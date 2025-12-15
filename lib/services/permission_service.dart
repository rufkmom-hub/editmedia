import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 서비스
class PermissionService {
  /// 카메라 권한 요청
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) {
      // 웹에서는 브라우저가 자동으로 권한 요청
      return true;
    }

    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      if (kDebugMode) {
        debugPrint('카메라 권한이 거부되었습니다.');
      }
      return false;
    } else if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        debugPrint('카메라 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// 사진 접근 권한 요청 (Android 13+ 대응)
  static Future<bool> requestPhotoPermission() async {
    if (kIsWeb) {
      // 웹에서는 브라우저가 자동으로 권한 요청
      return true;
    }

    // Android 13 이상에서는 photos 권한 사용
    PermissionStatus status;
    try {
      status = await Permission.photos.request();
    } catch (e) {
      // Android 12 이하에서는 storage 권한 사용
      status = await Permission.storage.request();
    }
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      if (kDebugMode) {
        debugPrint('사진 접근 권한이 거부되었습니다.');
      }
      return false;
    } else if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        debugPrint('사진 접근 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// 저장소 쓰기 권한 요청
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      // 웹에서는 브라우저가 자동으로 권한 요청
      return true;
    }

    final status = await Permission.storage.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      if (kDebugMode) {
        debugPrint('저장소 권한이 거부되었습니다.');
      }
      return false;
    } else if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        debugPrint('저장소 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }
      await openAppSettings();
      return false;
    }
    
    return false;
  }
}
