import 'package:flutter/material.dart';
import '../models/post.dart';

class CreatePostDialog extends StatefulWidget {
  final Future<void> Function(String text, PostKind kind) onPostCreate;

  const CreatePostDialog({
    super.key,
    required this.onPostCreate,
  });

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _textController = TextEditingController();
  PostKind _selectedKind = PostKind.user;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {}); // 文字数カウンターを更新
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿内容を入力してください')),
      );
      return;
    }

    if (text.length > 280) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿は280文字以内で入力してください')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onPostCreate(text, _selectedKind);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しい投稿'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 投稿種別選択
          const Text('投稿種別', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<PostKind>(
                  title: const Text('ユーザー投稿'),
                  value: PostKind.user,
                  groupValue: _selectedKind,
                  onChanged: (value) {
                    setState(() {
                      _selectedKind = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<PostKind>(
                  title: const Text('土地の記憶'),
                  value: PostKind.land,
                  groupValue: _selectedKind,
                  onChanged: (value) {
                    setState(() {
                      _selectedKind = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 投稿内容入力
          const Text('投稿内容', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 4,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: 'ここに投稿内容を入力してください...',
              border: OutlineInputBorder(),
              counterText: '', // 文字数カウンターを非表示
            ),
            enabled: !_isSubmitting,
          ),
          
          const SizedBox(height: 8),
          
          // 文字数表示
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_textController.text.length}/280',
              style: TextStyle(
                fontSize: 12,
                color: _textController.text.length > 280 
                  ? Colors.red 
                  : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('投稿'),
        ),
      ],
    );
  }
}