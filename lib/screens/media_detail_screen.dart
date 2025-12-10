import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../providers/folder_provider.dart';
import '../widgets/add_memo_dialog.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem media;
  final VoidCallback onMemoUpdated;
  final VoidCallback onDeleted;

  const MediaDetailScreen({
    super.key,
    required this.media,
    required this.onMemoUpdated,
    required this.onDeleted,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.mediaType == MediaType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.media.filePath));
    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController!.setLooping(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동영상 로드 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.media.mediaType == MediaType.video ? '동영상' : '사진',
        ),
        actions: [
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMediaPreview(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '메모',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _showMemoDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('편집'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.media.memo?.isEmpty ?? true
                          ? '메모가 없습니다. 편집 버튼을 눌러 메모를 추가하세요.'
                          : widget.media.memo!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.media.mediaType == MediaType.video) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: _isVideoInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
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
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      );
    }

    return Image.file(
      File(widget.media.filePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 300,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.broken_image, size: 64),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.category,
              '타입',
              widget.media.mediaType == MediaType.video ? '동영상' : '사진',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              '생성일',
              DateFormat('yyyy-MM-dd HH:mm').format(widget.media.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.folder,
              '경로',
              widget.media.filePath,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showMemoDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddMemoDialog(
        initialMemo: widget.media.memo ?? '',
      ),
    );

    if (result != null && mounted) {
      final provider = context.read<FolderProvider>();
      await provider.updateMediaMemo(widget.media.id, result);
      widget.media.memo = result;
      setState(() {});
      widget.onMemoUpdated();
    }
  }

  Future<void> _shareMedia() async {
    if (File(widget.media.filePath).existsSync()) {
      await Share.shareXFiles(
        [XFile(widget.media.filePath)],
        text: widget.media.memo ?? '',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 찾을 수 없습니다')),
      );
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<FolderProvider>();
      await provider.deleteMedia(widget.media.id);
      widget.onDeleted();
    }
  }
}
