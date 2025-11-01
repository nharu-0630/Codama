import 'package:codama/core/constants/config.dart';
import 'package:flutter/material.dart';

class CreatePostDialog extends StatefulWidget {
  final Future<void> Function(String text) onPostCreate;

  const CreatePostDialog({super.key, required this.onPostCreate});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _textController = TextEditingController();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投稿内容を入力してください')));
      return;
    }

    if (text.length > Config.maxPostLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿は${Config.maxPostLength}文字以内で入力してください')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onPostCreate(text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('投稿に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Config.customLightBrown,
      title: Text(
        'あなたの心の声を聞かせて',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 投稿内容入力
          TextField(
            controller: _textController,
            maxLines: 4,
            maxLength: Config.maxPostLength,
            decoration: const InputDecoration(
              hintText: 'ここに投稿内容を入力してください...',
              border: OutlineInputBorder(),
              counterText: '', // 文字数カウンターを非表示
            ),
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: Config.spacingSmall),

          // 文字数表示
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_textController.text.length}/${Config.maxPostLength}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _textController.text.length > Config.maxPostLength
                    ? Config.neutralRed
                    : Config.neutralGrey,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Config.brandOrange,
            foregroundColor: Config.neutralWhite,
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: Config.iconSizeMedium,
                  height: Config.iconSizeMedium,
                  child: CircularProgressIndicator(
                    strokeWidth: Config.borderWidthThin,
                    color: Config.neutralWhite,
                  ),
                )
              : const Text('投稿'),
        ),
      ],
    );
  }
}
