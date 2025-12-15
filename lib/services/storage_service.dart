import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/folder_model.dart';
import '../models/media_item.dart';

class StorageService {
  static const String _foldersBox = 'folders';
  static const String _mediaBox = 'media';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_foldersBox);
    await Hive.openBox(_mediaBox);
  }

  // Folder operations
  Box get _folders => Hive.box(_foldersBox);
  Box get _media => Hive.box(_mediaBox);

  Future<void> saveFolder(FolderModel folder) async {
    await _folders.put(folder.id, jsonEncode(folder.toJson()));
  }

  Future<void> deleteFolder(String folderId) async {
    await _folders.delete(folderId);
    // Delete all media in folder
    final mediaItems = await getMediaInFolder(folderId);
    for (var item in mediaItems) {
      await _media.delete(item.id);
    }
  }

  Future<List<FolderModel>> getAllFolders() async {
    final folders = <FolderModel>[];
    for (var key in _folders.keys) {
      final jsonStr = _folders.get(key) as String;
      final folder = FolderModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      folders.add(folder);
    }
    folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return folders;
  }

  Future<FolderModel?> getFolder(String id) async {
    final jsonStr = _folders.get(id) as String?;
    if (jsonStr == null) return null;
    return FolderModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  // Media operations
  Future<void> saveMedia(MediaItem media) async {
    await _media.put(media.id, jsonEncode(media.toJson()));
    
    // Update folder media count
    final folder = await getFolder(media.folderId);
    if (folder != null) {
      folder.mediaCount++;
      if (folder.coverImagePath == null && media.mediaType == MediaType.image) {
        folder.coverImagePath = media.webDataUrl ?? media.filePath;
      }
      await saveFolder(folder);
    }
  }

  Future<void> updateMedia(MediaItem media) async {
    // Get old media to check if folder changed
    final oldMediaStr = _media.get(media.id) as String?;
    if (oldMediaStr != null) {
      final oldMedia = MediaItem.fromJson(jsonDecode(oldMediaStr) as Map<String, dynamic>);
      
      // If folder changed, update both folders
      if (oldMedia.folderId != media.folderId) {
        final mediaPath = media.webDataUrl ?? media.filePath;
        
        // Update old folder
        final oldFolder = await getFolder(oldMedia.folderId);
        if (oldFolder != null) {
          oldFolder.mediaCount = (oldFolder.mediaCount - 1).clamp(0, 999999);
          
          // If removed media was cover image, update it
          if (oldFolder.coverImagePath == mediaPath) {
            final remainingMedia = await getMediaInFolder(oldMedia.folderId);
            final firstImage = remainingMedia.where((m) => m.id != media.id && m.mediaType == MediaType.image).firstOrNull;
            oldFolder.coverImagePath = firstImage != null ? (firstImage.webDataUrl ?? firstImage.filePath) : null;
          }
          
          await saveFolder(oldFolder);
        }
        
        // Update new folder
        final newFolder = await getFolder(media.folderId);
        if (newFolder != null) {
          newFolder.mediaCount++;
          if (media.mediaType == MediaType.image && (newFolder.coverImagePath == null || newFolder.mediaCount == 1)) {
            newFolder.coverImagePath = mediaPath;
          }
          await saveFolder(newFolder);
        }
      }
    }
    
    await _media.put(media.id, jsonEncode(media.toJson()));
  }

  Future<void> deleteMedia(String mediaId) async {
    final mediaStr = _media.get(mediaId) as String?;
    if (mediaStr != null) {
      final media = MediaItem.fromJson(jsonDecode(mediaStr) as Map<String, dynamic>);
      final mediaPath = media.webDataUrl ?? media.filePath;
      await _media.delete(mediaId);
      
      // Update folder media count and cover image
      final folder = await getFolder(media.folderId);
      if (folder != null) {
        folder.mediaCount = (folder.mediaCount - 1).clamp(0, 999999);
        
        // If deleted media was cover image, update it
        if (folder.coverImagePath == mediaPath) {
          final remainingMedia = await getMediaInFolder(media.folderId);
          final firstImage = remainingMedia.where((m) => m.mediaType == MediaType.image).firstOrNull;
          folder.coverImagePath = firstImage != null ? (firstImage.webDataUrl ?? firstImage.filePath) : null;
        }
        
        await saveFolder(folder);
      }
    }
  }

  Future<List<MediaItem>> getMediaInFolder(String folderId) async {
    final mediaItems = <MediaItem>[];
    for (var key in _media.keys) {
      final jsonStr = _media.get(key) as String;
      final media = MediaItem.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      if (media.folderId == folderId) {
        mediaItems.add(media);
      }
    }
    mediaItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mediaItems;
  }

  Future<MediaItem?> getMedia(String id) async {
    final jsonStr = _media.get(id) as String?;
    if (jsonStr == null) return null;
    return MediaItem.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  // Calculate total storage size
  Future<int> getTotalStorageSize() async {
    int totalSize = 0;
    for (var key in _media.keys) {
      final jsonStr = _media.get(key) as String;
      final media = MediaItem.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      totalSize += media.fileSize ?? 0;
    }
    return totalSize;
  }

  // Get all media items
  Future<List<MediaItem>> getAllMedia() async {
    final mediaItems = <MediaItem>[];
    for (var key in _media.keys) {
      final jsonStr = _media.get(key) as String;
      final media = MediaItem.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      mediaItems.add(media);
    }
    return mediaItems;
  }
}
