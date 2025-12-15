import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/folder_provider.dart';
import '../models/folder_model.dart';

class RenameFolderDialog extends StatefulWidget {
  final FolderModel folder;
  
  const RenameFolderDialog({
    super.key,
    required this.folder,
  });

  @override
  State<RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<RenameFolderDialog> {
  late final TextEditingController _controller;
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('폴더 이름 수정'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: '새 폴더 이름을 입력하세요',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        enabled: !_isRenaming,
        onSubmitted: (_) => _renameFolder(),
      ),
      actions: [
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isRenaming ? null : _renameFolder,
          child: _isRenaming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('수정'),
        ),
      ],
    );
  }

  Future<void> _renameFolder() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('폴더 이름을 입력해주세요')),
      );
      return;
    }

    if (newName == widget.folder.name) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isRenaming = true;
    });

    try {
      final provider = context.read<FolderProvider>();
      await provider.updateFolderName(widget.folder.id, newName);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 이름이 "$newName"(으)로 변경되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 이름 변경 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRenaming = false;
        });
      }
    }
  }
}
