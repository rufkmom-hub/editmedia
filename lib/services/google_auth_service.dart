import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/// Google 인증 및 API 서비스
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Google Sign In 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // Drive 파일 읽기/쓰기
      sheets.SheetsApi.spreadsheetsScope, // Sheets 읽기/쓰기
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  sheets.SheetsApi? _sheetsApi;

  /// 현재 로그인된 사용자
  GoogleSignInAccount? get currentUser => _currentUser;

  /// 로그인 여부
  bool get isSignedIn => _currentUser != null;

  /// Drive API 인스턴스
  drive.DriveApi? get driveApi => _driveApi;

  /// Sheets API 인스턴스
  sheets.SheetsApi? get sheetsApi => _sheetsApi;

  /// 초기화 및 자동 로그인 시도
  Future<void> initialize() async {
    try {
      // 이전 로그인 세션 복원 시도
      _currentUser = await _googleSignIn.signInSilently();
      
      if (_currentUser != null) {
        await _initializeApis();
        if (kDebugMode) {
          debugPrint('✅ Google 자동 로그인 성공: ${_currentUser!.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Google 자동 로그인 실패: $e');
      }
    }
  }

  /// Google 로그인
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      
      if (_currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ 사용자가 로그인을 취소했습니다.');
        }
        return false;
      }

      await _initializeApis();
      
      if (kDebugMode) {
        debugPrint('✅ Google 로그인 성공: ${_currentUser!.email}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google 로그인 실패: $e');
      }
      return false;
    }
  }

  /// Google 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      _sheetsApi = null;
      
      if (kDebugMode) {
        debugPrint('✅ Google 로그아웃 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google 로그아웃 실패: $e');
      }
    }
  }

  /// API 클라이언트 초기화
  Future<void> _initializeApis() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      
      if (httpClient == null) {
        throw Exception('HTTP 클라이언트 생성 실패');
      }

      _driveApi = drive.DriveApi(httpClient);
      _sheetsApi = sheets.SheetsApi(httpClient);
      
      if (kDebugMode) {
        debugPrint('✅ Google API 클라이언트 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google API 초기화 실패: $e');
      }
      rethrow;
    }
  }

  /// 로그인 상태 스트림
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
}
