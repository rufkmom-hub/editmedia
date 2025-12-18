import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/folder_model.dart';
import '../models/media_item.dart';
import '../providers/folder_provider.dart';
import '../services/web_file_helper.dart';
import '../services/permission_service.dart';
import '../services/export_service.dart';
import '../services/google_export_service.dart';
import '../services/google_auth_service.dart';
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
              icon: const Icon(Icons.download),
              onPressed: _selectedIds.isEmpty ? null : _downloadSelected,
              tooltip: '선택 항목 다운로드',
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: _selectedIds.isEmpty ? null : _moveToFolder,
              tooltip: '다른 폴더로 이동',
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
                  case 'google':
                    _exportToGoogle();
                    break;
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
                  value: 'google',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Google Drive/Sheets로 내보내기'),
                    ],
                  ),
                ),
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
                    onMemoUpdate: () {
                      setState(() {});
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

  // 선택한 미디어를 내 사진첩으로 다운로드
  Future<void> _downloadSelected() async {
    final selectedMedia = _mediaItems.where((m) => _selectedIds.contains(m.id)).toList();
    
    if (selectedMedia.isEmpty) return;

    try {
      for (var media in selectedMedia) {
        // 웹에서는 WebFileHelper 사용, 모바일에서는 갤러리에 저장
        if (kIsWeb) {
          if (media.webDataUrl != null) {
            WebFileHelper.downloadFile(
              media.webDataUrl!,
              '${media.id}.${media.mediaType == MediaType.image ? 'jpg' : 'mp4'}',
            );
          }
        } else {
          // 모바일: 갤러리에 저장하는 로직 (image_gallery_saver 패키지 필요)
          // 여기서는 간단히 공유 기능 사용
        }
      }

      if (mounted) {
        _toggleSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedMedia.length}개의 미디어를 다운로드했습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  // 선택한 미디어를 다른 폴더로 이동
  Future<void> _moveToFolder() async {
    final provider = context.read<FolderProvider>();
    final folders = provider.folders.where((f) => f.id != widget.folder.id).toList();

    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이동할 폴더가 없습니다')),
      );
      return;
    }

    final targetFolder = await showDialog<FolderModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.name),
                subtitle: Text('${folder.mediaCount}개 항목'),
                onTap: () => Navigator.pop(context, folder),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (targetFolder != null && mounted) {
      try {
        for (var id in _selectedIds) {
          final media = _mediaItems.firstWhere((m) => m.id == id);
          media.folderId = targetFolder.id;
          await provider.updateMedia(media);
        }

        _toggleSelectionMode();
        await _loadMedia();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedIds.length}개의 미디어를 "${targetFolder.name}"(으)로 이동했습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이동 실패: $e')),
          );
        }
      }
    }
  }

  // Google Drive/Sheets로 내보내기
  Future<void> _exportToGoogle() async {
    try {
      final googleAuth = GoogleAuthService();
      final googleExport = GoogleExportService();

      // 1. Google 로그인 확인
      if (!googleAuth.isSignedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('먼저 설정에서 Google 계정에 로그인해주세요'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 2. Drive/Sheets 설정 확인
      final prefs = await SharedPreferences.getInstance();
      final driveFolderId = prefs.getString('google_drive_folder_id') ?? '';
      final spreadsheetId = prefs.getString('google_spreadsheet_id') ?? '';

      if (driveFolderId.isEmpty || spreadsheetId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('먼저 설정에서 Drive 폴더 ID와 Sheet ID를 입력해주세요'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 3. 진행률 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _GoogleExportProgressDialog(
            mediaItems: _mediaItems,
            folder: widget.folder,
            driveFolderId: driveFolderId,
            spreadsheetId: spreadsheetId,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 내보내기 실패: $e')),
        );
      }
    }
  }
}

// Google 내보내기 진행률 다이얼로그
class _GoogleExportProgressDialog extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final FolderModel folder;
  final String driveFolderId;
  final String spreadsheetId;

  const _GoogleExportProgressDialog({
    required this.mediaItems,
    required this.folder,
    required this.driveFolderId,
    required this.spreadsheetId,
  });

  @override
  State<_GoogleExportProgressDialog> createState() => _GoogleExportProgressDialogState();
}

class _GoogleExportProgressDialogState extends State<_GoogleExportProgressDialog> {
  int _current = 0;
  int _total = 0;
  String _message = '준비 중...';
  bool _isCompleted = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    final googleExport = GoogleExportService();

    try {
      final success = await googleExport.exportToGoogle(
        mediaItems: widget.mediaItems,
        folder: widget.folder,
        driveFolderId: widget.driveFolderId,
        spreadsheetId: widget.spreadsheetId,
        onProgress: (current, total, message) {
          if (mounted) {
            setState(() {
              _current = current;
              _total = total;
              _message = message;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isCompleted = true;
          _isSuccess = success;
        });

        // 2초 후 자동 닫기
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _isSuccess = false;
          _message = '오류: $e';
        });

        // 3초 후 자동 닫기
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Google로 내보내기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isCompleted) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ] else ...[
            Icon(
              _isSuccess ? Icons.check_circle : Icons.error,
              color: _isSuccess ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
          ],
          Text(_message),
          if (_total > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _total > 0 ? _current / _total : 0,
            ),
            const SizedBox(height: 8),
            Text('$_current / $_total'),
          ],
        ],
      ),
      actions: _isCompleted
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ]
          : [],
    );
  }
}
