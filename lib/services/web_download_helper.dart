// Web-only download helper
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(String dataUrl, String fileName) {
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = dataUrl;
  anchor.download = fileName;
  anchor.click();
}
