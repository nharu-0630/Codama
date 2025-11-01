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
      content: TextField(
        controller: _textController,
        maxLines: 4,
        maxLength: Config.maxPostLength,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        enabled: !_isSubmitting,
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('とじる'),
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
