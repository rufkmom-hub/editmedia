import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/media_item.dart';
import '../services/storage_service.dart';

class FolderProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  List<FolderModel> _folders = [];
  bool _isLoading = false;

  List<FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;

  Future<void> loadFolders() async {
    _isLoading = true;
    notifyListeners();

    _folders = await _storage.getAllFolders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createFolder(String name) async {
    final folder = FolderModel(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );

    await _storage.saveFolder(folder);
    await loadFolders();
  }

  Future<void> deleteFolder(String folderId) async {
    await _storage.deleteFolder(folderId);
    await loadFolders();
  }

  Future<List<MediaItem>> getMediaInFolder(String folderId) async {
    return await _storage.getMediaInFolder(folderId);
  }

  Future<void> addMedia(MediaItem media) async {
    await _storage.saveMedia(media);
    await loadFolders();
  }

  Future<void> updateMediaMemo(String mediaId, String memo) async {
    final media = await _storage.getMedia(mediaId);
    if (media != null) {
      media.memo = memo;
      await _storage.updateMedia(media);
      notifyListeners();
    }
  }

  Future<void> deleteMedia(String mediaId) async {
    await _storage.deleteMedia(mediaId);
    await loadFolders();
  }
}
