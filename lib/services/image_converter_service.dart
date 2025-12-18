import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 이미지 JPG 변환 서비스
class ImageConverterService {
  /// 이미지를 JPG로 변환
  /// [imageBytes] 원본 이미지 바이트
  /// [quality] JPG 품질 (1-100, 기본값 90)
  /// Returns: JPG 형식의 바이트 데이터
  static Future<Uint8List?> convertToJpg(
    Uint8List imageBytes, {
    int quality = 90,
  }) async {
    try {
      // 이미지 디코딩
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        if (kDebugMode) {
          debugPrint('❌ 이미지 디코딩 실패');
        }
        return null;
      }

      // JPG로 인코딩
      final jpgBytes = img.encodeJpg(image, quality: quality);
      
      if (kDebugMode) {
        final originalSize = imageBytes.length;
        final convertedSize = jpgBytes.length;
        final reduction = ((originalSize - convertedSize) / originalSize * 100).toStringAsFixed(1);
        debugPrint('✅ JPG 변환 완료: ${originalSize ~/ 1024}KB → ${convertedSize ~/ 1024}KB (${reduction}% 감소)');
      }
      
      return Uint8List.fromList(jpgBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JPG 변환 실패: $e');
      }
      return null;
    }
  }

  /// 이미지가 JPG 형식인지 확인
  static bool isJpg(Uint8List imageBytes) {
    // JPG 파일 시그니처: FF D8 FF
    if (imageBytes.length < 3) return false;
    return imageBytes[0] == 0xFF &&
           imageBytes[1] == 0xD8 &&
           imageBytes[2] == 0xFF;
  }

  /// 이미지 형식 감지
  static String? detectImageFormat(Uint8List imageBytes) {
    if (imageBytes.length < 4) return null;

    // PNG: 89 50 4E 47
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'PNG';
    }

    // JPG: FF D8 FF
    if (imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF) {
      return 'JPG';
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'WebP';
    }

    // GIF: 47 49 46 38
    if (imageBytes[0] == 0x47 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x38) {
      return 'GIF';
    }

    return 'Unknown';
  }
}
