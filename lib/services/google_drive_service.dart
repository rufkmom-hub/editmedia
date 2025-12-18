import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'google_auth_service.dart';
import 'image_converter_service.dart';

/// Google Drive 업로드 서비스
class GoogleDriveService {
  final GoogleAuthService _authService = GoogleAuthService();

  /// 이미지를 Google Drive에 업로드
  /// [imageBytes] 이미지 바이트 데이터
  /// [folderName] 앱 내 폴더명 (파일명 접두사로 사용)
  /// [fileName] 원본 파일명
  /// [folderId] Google Drive 폴더 ID
  /// Returns: 업로드된 파일의 공유 링크
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String folderName,
    required String fileName,
    required String folderId,
  }) async {
    try {
      if (_authService.driveApi == null) {
        throw Exception('Drive API가 초기화되지 않았습니다. 먼저 Google 로그인을 해주세요.');
      }

      // 1. 이미지를 JPG로 변환
      Uint8List? jpgBytes;
      if (ImageConverterService.isJpg(imageBytes)) {
        jpgBytes = imageBytes;
        if (kDebugMode) {
          debugPrint('✅ 이미 JPG 형식입니다. 변환 생략');
        }
      } else {
        final format = ImageConverterService.detectImageFormat(imageBytes);
        if (kDebugMode) {
          debugPrint('🔄 $format → JPG 변환 시작...');
        }
        jpgBytes = await ImageConverterService.convertToJpg(imageBytes);
        
        if (jpgBytes == null) {
          throw Exception('이미지 JPG 변환 실패');
        }
      }

      // 2. 파일명 생성: "폴더명_원본파일명.jpg"
      final fileNameWithoutExt = fileName.split('.').first;
      final newFileName = '${folderName}_$fileNameWithoutExt.jpg';

      if (kDebugMode) {
        debugPrint('📤 업로드 시작: $newFileName (${jpgBytes.length ~/ 1024}KB)');
      }

      // 3. Drive 파일 메타데이터 생성
      final driveFile = drive.File()
        ..name = newFileName
        ..parents = [folderId];

      // 4. 파일 업로드
      final media = drive.Media(
        Stream.value(jpgBytes),
        jpgBytes.length,
      );

      final uploadedFile = await _authService.driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink',
      );

      if (uploadedFile.id == null) {
        throw Exception('파일 업로드 실패: ID가 없습니다.');
      }

      // 5. 파일을 공개 링크로 설정
      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';

      await _authService.driveApi!.permissions.create(
        permission,
        uploadedFile.id!,
      );

      // 6. 공유 링크 반환
      final shareLink = uploadedFile.webViewLink ?? uploadedFile.webContentLink;
      
      if (kDebugMode) {
        debugPrint('✅ 업로드 완료: $newFileName');
        debugPrint('🔗 공유 링크: $shareLink');
      }

      return shareLink;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Drive 업로드 실패: $e');
      }
      rethrow;
    }
  }

  /// 여러 이미지를 일괄 업로드
  /// Returns: Map<원본파일명, 공유링크>
  Future<Map<String, String>> uploadMultipleImages({
    required List<Uint8List> imageBytesList,
    required List<String> fileNames,
    required String folderName,
    required String folderId,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <String, String>{};

    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final shareLink = await uploadImage(
          imageBytes: imageBytesList[i],
          folderName: folderName,
          fileName: fileNames[i],
          folderId: folderId,
        );

        if (shareLink != null) {
          results[fileNames[i]] = shareLink;
        }

        // 진행률 콜백
        if (onProgress != null) {
          onProgress(i + 1, imageBytesList.length);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ${fileNames[i]} 업로드 실패: $e');
        }
        // 계속 진행
      }
    }

    return results;
  }
}
