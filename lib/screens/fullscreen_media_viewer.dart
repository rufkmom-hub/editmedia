import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../providers/folder_provider.dart';
import '../services/web_file_helper.dart';
import '../widgets/add_memo_dialog.dart';

class FullscreenMediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;
  final Function(String) onDelete;
  final VoidCallback? onMemoUpdate;

  const FullscreenMediaViewer({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
    required this.onDelete,
    this.onMemoUpdate,
  });

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeCurrentMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentMedia() async {
    final media = widget.mediaItems[_currentIndex];
    
    // Dispose previous video controller
    await _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    if (media.mediaType == MediaType.video) {
      if (!kIsWeb && File(media.filePath).existsSync()) {
        _videoController = VideoPlayerController.file(File(media.filePath));
        try {
          await _videoController!.initialize();
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('동영상 로드 실패: $e')),
            );
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMedia = widget.mediaItems[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              title: Text('${_currentIndex + 1} / ${widget.mediaItems.length}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.note_add),
                  onPressed: _showMemoDialog,
                  tooltip: '메모',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareMedia,
                  tooltip: '공유',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteMedia,
                  tooltip: '삭제',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeCurrentMedia();
              },
              itemBuilder: (context, index) {
                final media = widget.mediaItems[index];
                return _buildMediaView(media);
              },
            ),
            
            // Page indicator
            if (_showControls && widget.mediaItems.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.mediaItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaView(MediaItem media) {
    if (media.mediaType == MediaType.video) {
      return _buildVideoView(media);
    } else {
      return _buildImageView(media);
    }
  }

  Widget _buildImageView(MediaItem media) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: kIsWeb && media.webDataUrl != null
            ? _buildWebImage(media.webDataUrl!)
            : !kIsWeb && File(media.filePath).existsSync()
                ? Image.file(File(media.filePath))
                : _buildErrorPlaceholder(),
      ),
    );
  }

  Widget _buildWebImage(String dataUrl) {
    final bytes = WebFileHelper.dataUrlToBytes(dataUrl);
    if (bytes != null) {
      return Image.memory(bytes);
    }
    return _buildErrorPlaceholder();
  }

  Widget _buildVideoView(MediaItem media) {
    if (_isVideoInitialized && _videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (_showControls)
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 64,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildErrorPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            '미디어를 불러올 수 없습니다',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _showMemoDialog() async {
    final currentMedia = widget.mediaItems[_currentIndex];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddMemoDialog(
        initialMemo: currentMedia.memo ?? '',
      ),
    );

    if (result != null && mounted) {
      final provider = context.read<FolderProvider>();
      await provider.updateMediaMemo(currentMedia.id, result);
      currentMedia.memo = result;
      setState(() {});
      widget.onMemoUpdate?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모가 저장되었습니다')),
      );
    }
  }

  Future<void> _shareMedia() async {
    final currentMedia = widget.mediaItems[_currentIndex];
    
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('웹에서는 다운로드를 통해 파일을 저장할 수 있습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      if (File(currentMedia.filePath).existsSync()) {
        await Share.shareXFiles(
          [XFile(currentMedia.filePath)],
          text: currentMedia.memo ?? '',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 찾을 수 없습니다')),
        );
      }
    }
  }

  Future<void> _deleteMedia() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미디어 삭제'),
        content: const Text('이 미디어를 삭제하시겠습니까?'),
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
      final currentMedia = widget.mediaItems[_currentIndex];
      final provider = context.read<FolderProvider>();
      await provider.deleteMedia(currentMedia.id);
      
      widget.onDelete(currentMedia.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미디어를 삭제했습니다')),
        );
      }
    }
  }
}
