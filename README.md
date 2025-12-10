# Media Studio 📸

사진과 동영상을 폴더별로 관리하고 메모를 추가할 수 있는 미디어 관리 앱

![Flutter](https://img.shields.io/badge/Flutter-3.35.4-blue)
![Dart](https://img.shields.io/badge/Dart-3.9.2-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 주요 기능

### 📁 폴더 관리
- 폴더 생성 및 삭제
- 폴더별 미디어 분류
- 커버 이미지 자동 설정
- 미디어 개수 표시

### 📷 미디어 관리
- 사진/동영상 촬영 및 추가
- 갤러리에서 여러 파일 선택
- 3x3 그리드 썸네일 뷰
- 전체화면 뷰어 (확대/축소, 스와이프)

### ✅ 다중 선택
- 개별/전체 선택 모드
- 선택한 미디어 일괄 공유
- 선택한 미디어 일괄 삭제
- 시각적 선택 표시

### 📝 메모 기능
- 각 미디어에 메모 추가
- 메모 편집 및 수정
- 메모 아이콘 표시

### 📤 공유 기능
- 개별 미디어 공유
- 다중 미디어 공유
- 카카오톡, 메신저 지원
- 웹: 다운로드 기능

### 💾 저장소 관리
- 로컬 저장소 사용
- 전체 용량 표시
- 미디어 개수 표시
- 실시간 새로고침

## 🎨 디자인

- **Material Design 3** 스타일
- 파란색/흰색 그라데이션
- 카드 기반 레이아웃
- 반응형 그리드

## 🛠️ 기술 스택

### Flutter Packages
```yaml
dependencies:
  flutter: sdk: flutter
  provider: 6.1.5+1           # 상태 관리
  hive: 2.2.3                 # 로컬 데이터베이스
  hive_flutter: 1.1.0         # Hive Flutter 통합
  image_picker: 1.1.2         # 카메라/갤러리
  camera: 0.11.0+2            # 카메라 접근
  video_player: 2.9.2         # 동영상 재생
  share_plus: 10.1.2          # 공유 기능
  path_provider: 2.1.5        # 파일 경로
  uuid: 4.5.1                 # 고유 ID 생성
  intl: 0.19.0                # 날짜 포맷
```

## 🚀 시작하기

### 요구사항
- Flutter 3.35.4 이상
- Dart 3.9.2 이상

### 설치

```bash
# 저장소 클론
git clone https://github.com/your-username/media-studio.git
cd media-studio

# 의존성 설치
flutter pub get

# 웹에서 실행
flutter run -d chrome

# Android에서 실행
flutter run -d android

# iOS에서 실행 (macOS 필요)
flutter run -d ios
```

### 빌드

```bash
# 웹 빌드
flutter build web --release

# Android APK 빌드
flutter build apk --release

# iOS 빌드 (macOS 필요)
flutter build ios --release
```

## 📱 플랫폼 지원

| 플랫폼 | 지원 여부 | 비고 |
|--------|----------|------|
| 🌐 Web | ✅ 완벽 지원 | IndexedDB 저장 |
| 🤖 Android | ✅ 완벽 지원 | 네이티브 카메라/공유 |
| 🍎 iOS | ✅ 지원 | macOS에서 빌드 필요 |

## 🌐 웹 배포

### GitHub Pages
```bash
# build/web 폴더를 docs로 복사
cp -r build/web docs/

# GitHub 푸시
git add docs/
git commit -m "Deploy to GitHub Pages"
git push

# Settings → Pages → Source: main branch, /docs folder
```

### Vercel
1. Vercel.com 가입
2. GitHub 저장소 연결
3. 자동 빌드 및 배포

### Firebase Hosting
```bash
firebase init hosting
firebase deploy
```

## 📂 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── folder_model.dart
│   └── media_item.dart
├── services/                 # 비즈니스 로직
│   ├── storage_service.dart
│   └── web_file_helper.dart
├── providers/                # 상태 관리
│   └── folder_provider.dart
├── screens/                  # 화면
│   ├── home_screen.dart
│   ├── folder_detail_screen.dart
│   ├── fullscreen_media_viewer.dart
│   └── media_detail_screen.dart
└── widgets/                  # 재사용 위젯
    ├── folder_card.dart
    ├── media_grid_item.dart
    ├── create_folder_dialog.dart
    └── add_memo_dialog.dart
```

## 🎯 사용 방법

1. **폴더 생성**: 홈 화면에서 "새 폴더" 버튼
2. **미디어 추가**: 폴더 안에서 카메라/갤러리 버튼
3. **전체화면 보기**: 미디어 클릭
4. **메모 추가**: 전체화면에서 메모 아이콘
5. **다중 선택**: 체크리스트 아이콘 또는 길게 누르기
6. **공유**: 선택 후 공유 버튼

## 🔧 개발 환경

- **Flutter SDK**: 3.35.4
- **Dart SDK**: 3.9.2
- **에디터**: VS Code / Android Studio
- **테스트**: Chrome (웹), Android Emulator

## 📝 라이선스

MIT License

## 👤 작성자

프로젝트 생성 날짜: 2024-12-10

## 🙏 기여

이슈 및 풀 리퀘스트 환영합니다!

## 📸 스크린샷

(스크린샷 추가 예정)

---

**Made with ❤️ using Flutter**
