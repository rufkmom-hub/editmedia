import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class WebFileHelper {
  // Convert XFile to base64 data URL for web storage
  static Future<String?> fileToDataUrl(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Determine MIME type
      String mimeType = 'image/jpeg';
      if (file.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (file.path.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (file.path.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (file.path.toLowerCase().endsWith('.mp4')) {
        mimeType = 'video/mp4';
      } else if (file.path.toLowerCase().endsWith('.mov')) {
        mimeType = 'video/quicktime';
      }
      
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error converting file to data URL: $e');
      }
      return null;
    }
  }

  // Get file size
  static Future<int> getFileSize(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.length;
    } catch (e) {
      return 0;
    }
  }

  // Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Convert data URL back to bytes
  static Uint8List? dataUrlToBytes(String dataUrl) {
    try {
      final base64String = dataUrl.split(',').last;
      return base64Decode(base64String);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error converting data URL to bytes: $e');
      }
      return null;
    }
  }
}
