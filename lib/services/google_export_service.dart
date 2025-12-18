import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/folder_model.dart';
import 'google_auth_service.dart';
import 'google_drive_service.dart';
import 'google_sheets_service.dart';
import 'web_file_helper.dart';

/// Google Drive/Sheets 통합 내보내기 서비스
class GoogleExportService {
  final GoogleAuthService _authService = GoogleAuthService();
  final GoogleDriveService _driveService = GoogleDriveService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  /// 선택한 미디어를 Google Drive/Sheets로 내보내기
  /// [mediaItems] 내보낼 미디어 목록
  /// [folder] 소속 폴더
  /// [driveFolderId] Google Drive 폴더 ID
  /// [spreadsheetId] Google Sheets ID
  /// [onProgress] 진행률 콜백 (current, total, message)
  Future<bool> exportToGoogle({
    required List<MediaItem> mediaItems,
    required FolderModel folder,
    required String driveFolderId,
    required String spreadsheetId,
    Function(int current, int total, String message)? onProgress,
  }) async {
    try {
      // 1. Google 로그인 확인
      if (!_authService.isSignedIn) {
        throw Exception('Google 계정에 로그인되어 있지 않습니다.');
      }

      if (kDebugMode) {
        debugPrint('📤 Google 내보내기 시작: ${mediaItems.length}개 파일');
      }

      // 2. 이미지 데이터 준비
      final imageBytesList = <Uint8List>[];
      final fileNames = <String>[];
      final memos = <String>[];

      for (var media in mediaItems) {
        // 이미지 바이트 가져오기
        final bytes = WebFileHelper.dataUrlToBytes(media.path);
        if (bytes != null) {
          imageBytesList.add(bytes);
          fileNames.add(media.name);
          memos.add(media.memo ?? '');
        }
      }

      if (imageBytesList.isEmpty) {
        throw Exception('내보낼 이미지가 없습니다.');
      }

      onProgress?.call(0, mediaItems.length, 'Drive에 업로드 중...');

      // 3. Google Drive에 업로드
      final uploadResults = await _driveService.uploadMultipleImages(
        imageBytesList: imageBytesList,
        fileNames: fileNames,
        folderName: folder.name,
        folderId: driveFolderId,
        onProgress: (current, total) {
          onProgress?.call(
            current,
            total + mediaItems.length, // Drive + Sheets 합산
            'Drive 업로드: $current/$total',
          );
        },
      );

      if (uploadResults.isEmpty) {
        throw Exception('Drive 업로드 실패');
      }

      onProgress?.call(
        mediaItems.length,
        mediaItems.length * 2,
        'Sheets에 기록 중...',
      );

      // 4. Google Sheets에 데이터 추가
      final sheetDataList = <Map<String, String>>[];
      
      for (int i = 0; i < fileNames.length; i++) {
        final fileName = fileNames[i];
        final driveLink = uploadResults[fileName];
        
        if (driveLink != null) {
          sheetDataList.add({
            'folderName': folder.name,
            'fileName': fileName,
            'memo': memos[i],
            'driveLink': driveLink,
          });
        }
      }

      final successCount = await _sheetsService.appendMultipleData(
        spreadsheetId: spreadsheetId,
        dataList: sheetDataList,
        onProgress: (current, total) {
          onProgress?.call(
            mediaItems.length + current,
            mediaItems.length * 2,
            'Sheets 기록: $current/$total',
          );
        },
      );

      if (kDebugMode) {
        debugPrint('✅ Google 내보내기 완료: $successCount/${mediaItems.length}개 성공');
      }

      onProgress?.call(
        mediaItems.length * 2,
        mediaItems.length * 2,
        '완료: $successCount개 성공',
      );

      return successCount > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google 내보내기 실패: $e');
      }
      onProgress?.call(0, mediaItems.length, '오류: $e');
      return false;
    }
  }

  /// Google 계정 연동 상태 확인
  bool get isGoogleConnected => _authService.isSignedIn;

  /// 현재 로그인된 Google 계정 이메일
  String? get currentUserEmail => _authService.currentUser?.email;
}
