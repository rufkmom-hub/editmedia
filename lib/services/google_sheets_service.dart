import 'package:flutter/foundation.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'google_auth_service.dart';

/// Google Sheets 데이터 입력 서비스
class GoogleSheetsService {
  final GoogleAuthService _authService = GoogleAuthService();

  /// Sheets에 데이터 추가
  /// [spreadsheetId] Google Sheets ID
  /// [folderName] 앱 내 폴더명
  /// [fileName] 파일명
  /// [memo] 사진 메모
  /// [driveLink] Drive 공유 링크
  Future<bool> appendData({
    required String spreadsheetId,
    required String folderName,
    required String fileName,
    required String memo,
    required String driveLink,
  }) async {
    try {
      if (_authService.sheetsApi == null) {
        throw Exception('Sheets API가 초기화되지 않았습니다. 먼저 Google 로그인을 해주세요.');
      }

      // HYPERLINK 수식 생성: =HYPERLINK("url", "표시텍스트")
      final hyperlinkFormula = '=HYPERLINK("$driveLink", "$fileName")';

      // 데이터 행 생성: [폴더명, 사진명(하이퍼링크), 메모]
      final values = [
        [folderName, hyperlinkFormula, memo],
      ];

      final valueRange = sheets.ValueRange()
        ..values = values;

      // Sheet에 데이터 추가 (마지막 행에 append)
      final response = await _authService.sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        'Sheet1!A:C', // 기본 시트의 A, B, C 열
        valueInputOption: 'USER_ENTERED', // 수식 해석 활성화
      );

      if (kDebugMode) {
        debugPrint('✅ Sheets에 데이터 추가 완료: $fileName');
        debugPrint('   업데이트된 범위: ${response.updates?.updatedRange}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sheets 데이터 추가 실패: $e');
      }
      return false;
    }
  }

  /// 여러 데이터를 일괄 추가
  Future<int> appendMultipleData({
    required String spreadsheetId,
    required List<Map<String, String>> dataList,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;

    for (int i = 0; i < dataList.length; i++) {
      final data = dataList[i];
      
      try {
        final success = await appendData(
          spreadsheetId: spreadsheetId,
          folderName: data['folderName'] ?? '',
          fileName: data['fileName'] ?? '',
          memo: data['memo'] ?? '',
          driveLink: data['driveLink'] ?? '',
        );

        if (success) {
          successCount++;
        }

        // 진행률 콜백
        if (onProgress != null) {
          onProgress(i + 1, dataList.length);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ${data['fileName']} Sheets 추가 실패: $e');
        }
        // 계속 진행
      }
    }

    return successCount;
  }

  /// Sheet 헤더 초기화 (최초 1회 실행)
  Future<bool> initializeSheet({
    required String spreadsheetId,
  }) async {
    try {
      if (_authService.sheetsApi == null) {
        throw Exception('Sheets API가 초기화되지 않았습니다.');
      }

      // 헤더 행 생성
      final headers = [
        ['폴더명', '사진명', '메모'],
      ];

      final valueRange = sheets.ValueRange()
        ..values = headers;

      // A1 셀부터 헤더 입력
      await _authService.sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        'Sheet1!A1:C1',
        valueInputOption: 'RAW',
      );

      // 헤더 스타일 적용 (굵게, 배경색)
      final requests = [
        sheets.Request()
          ..repeatCell = (sheets.RepeatCellRequest()
            ..range = (sheets.GridRange()
              ..sheetId = 0
              ..startRowIndex = 0
              ..endRowIndex = 1
              ..startColumnIndex = 0
              ..endColumnIndex = 3)
            ..cell = (sheets.CellData()
              ..userEnteredFormat = (sheets.CellFormat()
                ..backgroundColor = (sheets.Color()
                  ..red = 0.85
                  ..green = 0.85
                  ..blue = 0.85)
                ..textFormat = (sheets.TextFormat()
                  ..bold = true)))
            ..fields = 'userEnteredFormat(backgroundColor,textFormat)'),
      ];

      final batchUpdateRequest = sheets.BatchUpdateSpreadsheetRequest()
        ..requests = requests;

      await _authService.sheetsApi!.spreadsheets.batchUpdate(
        batchUpdateRequest,
        spreadsheetId,
      );

      if (kDebugMode) {
        debugPrint('✅ Sheet 헤더 초기화 완료');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sheet 초기화 실패: $e');
      }
      return false;
    }
  }
}
