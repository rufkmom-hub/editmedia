import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder_model.dart';
import '../models/media_item.dart';
import 'storage_service.dart';

class ExportService {
  final StorageService _storage = StorageService();

  /// Excel로 내보내기
  Future<String> exportToExcel(FolderModel folder, List<MediaItem> mediaItems) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // 헤더
    sheet.appendRow([
      TextCellValue('번호'),
      TextCellValue('파일명'),
      TextCellValue('타입'),
      TextCellValue('메모'),
      TextCellValue('생성일'),
    ]);

    // 데이터
    for (var i = 0; i < mediaItems.length; i++) {
      var media = mediaItems[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(media.filePath.split('/').last),
        TextCellValue(media.mediaType == MediaType.image ? '사진' : '동영상'),
        TextCellValue(media.memo ?? ''),
        TextCellValue(media.createdAt.toString().substring(0, 19)),
      ]);
    }

    // 파일 저장
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${folder.name}_export.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file.path;
  }

  /// HTML로 내보내기
  Future<String> exportToHTML(FolderModel folder, List<MediaItem> mediaItems) async {
    StringBuffer html = StringBuffer();
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html><head><meta charset="UTF-8">');
    html.writeln('<title>${folder.name}</title>');
    html.writeln('<style>');
    html.writeln('body { font-family: Arial; margin: 20px; }');
    html.writeln('h1 { color: #333; }');
    html.writeln('.media-item { border: 1px solid #ddd; margin: 10px 0; padding: 10px; }');
    html.writeln('</style></head><body>');
    html.writeln('<h1>${folder.name}</h1>');
    
    for (var i = 0; i < mediaItems.length; i++) {
      var media = mediaItems[i];
      html.writeln('<div class="media-item">');
      html.writeln('<p><strong>${i + 1}. ${media.filePath.split('/').last}</strong></p>');
      html.writeln('<p>타입: ${media.mediaType == MediaType.image ? '사진' : '동영상'}</p>');
      if (media.memo != null && media.memo!.isNotEmpty) {
        html.writeln('<p>메모: ${media.memo}</p>');
      }
      html.writeln('<p>생성일: ${media.createdAt.toString().substring(0, 19)}</p>');
      html.writeln('</div>');
    }
    
    html.writeln('</body></html>');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${folder.name}_export.html');
    await file.writeAsString(html.toString());

    return file.path;
  }

  /// ZIP으로 내보내기
  Future<String> exportToZIP(FolderModel folder, List<MediaItem> mediaItems) async {
    var archive = Archive();

    // 미디어 파일들을 아카이브에 추가
    for (var media in mediaItems) {
      try {
        final file = File(media.filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(
            media.filePath.split('/').last,
            bytes.length,
            bytes,
          ));
        }
      } catch (e) {
        print('파일 추가 실패: ${media.filePath}');
      }
    }

    // ZIP 파일로 인코딩
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // 저장
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${folder.name}_export.zip');
    await file.writeAsBytes(zipBytes!);

    return file.path;
  }
}
