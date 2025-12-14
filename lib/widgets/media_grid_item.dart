import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/web_file_helper.dart';

class MediaGridItem extends StatelessWidget {
  final MediaItem media;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const MediaGridItem({
    super.key,
    required this.media,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildThumbnail(context),
                ),
                
                // Selection overlay
                if (isSelectionMode)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected 
                          ? Colors.blue.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.2),
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 3)
                          : null,
                    ),
                  ),
                
                // Video indicator
                if (media.mediaType == MediaType.video)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                
                // Selection checkbox
                if (isSelectionMode)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Memo text at bottom
          if (media.memo != null && media.memo!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                media.memo!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (kIsWeb) {
      // Web platform: use base64 data URL
      if (media.webDataUrl != null) {
        final bytes = WebFileHelper.dataUrlToBytes(media.webDataUrl!);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(context);
            },
          );
        }
      }
      return _buildPlaceholder(context);
    } else {
      // Mobile platform: use file path
      if (File(media.filePath).existsSync()) {
        return Image.file(
          File(media.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(context);
          },
        );
      }
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        media.mediaType == MediaType.video ? Icons.videocam : Icons.image,
        size: 40,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
