import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../models/folder_model.dart';
import '../models/media_item.dart';
import '../providers/folder_provider.dart';
import '../services/web_file_helper.dart';
import '../services/permission_service.dart';
import '../services/export_service.dart';
import '../widgets/media_grid_item.dart';
import 'fullscreen_media_viewer.dart';

class FolderDetailScreen extends StatefulWidget {
  final FolderModel folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<MediaItem> _mediaItems = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  
  // Selection mode
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<FolderProvider>();
    final items = await provider.getMediaInFolder(widget.folder.id);

    setState(() {
      _mediaItems = items;
      _isLoading = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds = _mediaItems.map((m) => m.id).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedIds.length}개 선택됨'
            : widget.folder.name),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: '전체 선택',
            ),
            IconButton(
              icon: const Icon(Icons.deselect),
              onPressed: _deselectAll,
              tooltip: '선택 해제',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _selectedIds.isEmpty ? null : _shareSelected,
              tooltip: '선택 항목 공유',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              tooltip: '선택 항목 삭제',
            ),
          ] else if (_mediaItems.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: '내보내기',
              onSelected: (value) {
                switch (value) {
                  case 'excel':
                    _exportToExcel();
                    break;
                  case 'html':
                    _exportToHTML();
                    break;
                  case 'zip':
                    _exportToZIP();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 12),
                      Text('Excel로 내보내기'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'html',
                  child: Row(
                    children: [
                      Icon(Icons.code),
                      SizedBox(width: 12),
                      Text('HTML로 내보내기'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'zip',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip),
                      SizedBox(width: 12),
                      Text('ZIP으로 내보내기'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '선택 모드',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAllMedia,
              tooltip: '모두 공유',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mediaItems.isEmpty
              ? _buildEmptyView()
              : _buildMediaGrid(),
      floatingActionButton: _isSelectionMode ? null : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: _takePhoto,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'video',
            onPressed: _takeVideo,
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _pickFromGallery,
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '미디어가 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '하단 버튼을 눌러 사진이나 동영상을 추가하세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final media = _mediaItems[index];
        final isSelected = _selectedIds.contains(media.id);
        
        return MediaGridItem(
          media: media,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(media.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullscreenMediaViewer(
                    mediaItems: _mediaItems,
                    initialIndex: index,
                    onDelete: (id) {
                      _loadMedia();
                    },
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleSelection(media.id);
            }
          },
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    // 권한 체크
    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라 권한이 필요합니다')),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        await _saveMediaFile(photo, MediaType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 실패: $e')),
        );
      }
    }
  }

  Future<void> _takeVideo() async {
    // 권한 체크
    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라 권한이 필요합니다')),
        );
      }
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        await _saveMediaFile(video, MediaType.video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동영상 촬영 실패: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // 권한 체크
    final hasPermission = await PermissionService.requestPhotoPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 접근 권한이 필요합니다')),
        );
      }
      return;
    }

    try {
      final List<XFile> files = await _picker.pickMultipleMedia(
        imageQuality: 85,
      );

      for (var file in files) {
        final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
            file.path.toLowerCase().endsWith('.mov') ||
            file.path.toLowerCase().endsWith('.avi');
        await _saveMediaFile(
          file,
          isVideo ? MediaType.video : MediaType.image,
        );
      }
      
      if (mounted && files.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${files.length}개의 미디어가 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('갤러리에서 가져오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _saveMediaFile(XFile file, MediaType type) async {
    try {
      String? webDataUrl;
      int fileSize = 0;

      if (kIsWeb) {
        // For web: convert to base64 data URL
        webDataUrl = await WebFileHelper.fileToDataUrl(file);
        fileSize = await WebFileHelper.getFileSize(file);
      } else {
        // For mobile: get file size
        final fileEntity = File(file.path);
        fileSize = await fileEntity.length();
      }

      final media = MediaItem(
        id: const Uuid().v4(),
        folderId: widget.folder.id,
        filePath: file.path,
        mediaType: type,
        createdAt: DateTime.now(),
        webDataUrl: webDataUrl,
        fileSize: fileSize,
      );

      final provider = context.read<FolderProvider>();
      await provider.addMedia(media);
      await _loadMedia();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('미디어 저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _shareAllMedia() async {
    await _shareMediaItems(_mediaItems);
  }

  Future<void> _shareSelected() async {
    final selectedMedia = _mediaItems.where((m) => _selectedIds.contains(m.id)).toList();
    await _shareMediaItems(selectedMedia);
    _toggleSelectionMode();
  }

  Future<void> _shareMediaItems(List<MediaItem> items) async {
    if (kIsWeb) {
      // For web: download files
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('웹에서는 각 미디어를 개별적으로 다운로드할 수 있습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // For mobile: use share functionality
      final files = items
          .where((m) => File(m.filePath).existsSync())
          .map((m) => XFile(m.filePath))
          .toList();

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유할 미디어가 없습니다')),
        );
        return;
      }

      await Share.shareXFiles(
        files,
        subject: '${widget.folder.name} 폴더의 미디어',
        text: '${files.length}개의 미디어를 공유합니다',
      );
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final exportService = ExportService();
      final filePath = await exportService.exportToExcel(widget.folder, _mediaItems);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel 파일로 내보내기 완료\n$filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel 내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _exportToHTML() async {
    try {
      final exportService = ExportService();
      final filePath = await exportService.exportToHTML(widget.folder, _mediaItems);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTML 파일로 내보내기 완료\n$filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTML 내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _exportToZIP() async {
    try {
      final exportService = ExportService();
      final filePath = await exportService.exportToZIP(widget.folder, _mediaItems);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP 파일로 내보내기 완료\n$filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP 내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택 항목 삭제'),
        content: Text('선택한 ${_selectedIds.length}개의 미디어를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<FolderProvider>();
      for (var id in _selectedIds) {
        await provider.deleteMedia(id);
      }
      _toggleSelectionMode();
      await _loadMedia();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 미디어를 삭제했습니다')),
        );
      }
    }
  }
}
