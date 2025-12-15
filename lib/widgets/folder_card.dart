import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../services/web_file_helper.dart';
import 'package:intl/intl.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRename;
  final String? viewMode;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    this.onRename,
    this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    // 자세히 보기 모드: PC 스타일 가로 레이아웃
    if (viewMode == 'detail') {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 작은 폴더 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSmallIcon(context),
                ),
                const SizedBox(width: 16),
                // 폴더 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.mediaCount}개',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd').format(folder.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 액션 버튼들
                if (onRename != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onRename,
                    tooltip: '이름 수정',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 기본 모드: 세로 레이아웃 (기존 디자인)
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildCoverImage(context),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          folder.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onRename != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: onRename,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: '이름 수정',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${folder.mediaCount}개',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat('MM/dd').format(folder.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (folder.coverImagePath != null) {
      if (kIsWeb) {
        // Web: check if it's a data URL
        if (folder.coverImagePath!.startsWith('data:')) {
          final bytes = WebFileHelper.dataUrlToBytes(folder.coverImagePath!);
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
      } else {
        // Mobile: use file path
        if (File(folder.coverImagePath!).existsSync()) {
          return Image.file(
            File(folder.coverImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(context);
            },
          );
        }
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.folder_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSmallIcon(BuildContext context) {
    if (folder.coverImagePath != null) {
      if (kIsWeb) {
        // Web: check if it's a data URL
        if (folder.coverImagePath!.startsWith('data:')) {
          final bytes = WebFileHelper.dataUrlToBytes(folder.coverImagePath!);
          if (bytes != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorBuilder: (context, error, stackTrace) {
                  return _buildSmallPlaceholder(context);
                },
              ),
            );
          }
        }
      } else {
        // Mobile: use file path
        if (File(folder.coverImagePath!).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(folder.coverImagePath!),
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              errorBuilder: (context, error, stackTrace) {
                return _buildSmallPlaceholder(context);
              },
            ),
          );
        }
      }
    }

    return _buildSmallPlaceholder(context);
  }

  Widget _buildSmallPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.folder,
        size: 32,
        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}
