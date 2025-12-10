import 'package:flutter/material.dart';

class AddMemoDialog extends StatefulWidget {
  final String initialMemo;

  const AddMemoDialog({super.key, this.initialMemo = ''});

  @override
  State<AddMemoDialog> createState() => _AddMemoDialogState();
}

class _AddMemoDialogState extends State<AddMemoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메모 편집'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: '메모를 입력하세요',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
