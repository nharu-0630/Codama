import 'package:flutter/material.dart';

import '../models/bubble_position.dart';
import '../models/post.dart';

class BubbleWidget extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final BubbleDisplayKind displayKind;
  final bool showContent;

  const BubbleWidget({
    super.key,
    required this.post,
    this.onTap,
    required this.displayKind,
    this.showContent = true,
  });

  @override
  Widget build(BuildContext context) {
    // 4タイプに応じた色設定
    // 1. me: 自分の投稿 - 青系
    // 2. other: 他人の投稿 - 緑系
    // 3. landReply: LLMの返信 - 紫系（神秘的）
    // 4. userReply: ユーザーの返信 - オレンジ系
    // 一時投稿: 背景色を白っぽくする（枠の色はそのまま）

    final baseBubbleColor = switch (displayKind) {
      BubbleDisplayKind.me => Colors.blue.shade100,
      BubbleDisplayKind.other => Colors.green.shade100,
      BubbleDisplayKind.landReply => Colors.purple.shade50.withValues(
        alpha: 0.9,
      ),
      BubbleDisplayKind.userReply => Colors.orange.shade100,
    };

    // 一時投稿の場合は背景色を白っぽくする
    final bubbleColor = post.isTemporary
        ? Colors.white.withValues(alpha: 0.95)
        : baseBubbleColor;

    final borderColor = switch (displayKind) {
      BubbleDisplayKind.me => Colors.blue.shade400,
      BubbleDisplayKind.other => Colors.green.shade400,
      BubbleDisplayKind.landReply => Colors.purple.shade300,
      BubbleDisplayKind.userReply => Colors.orange.shade400,
    };

    final textColor = switch (displayKind) {
      BubbleDisplayKind.me => Colors.blue.shade800,
      BubbleDisplayKind.other => Colors.green.shade800,
      BubbleDisplayKind.landReply => Colors.purple.shade700,
      BubbleDisplayKind.userReply => Colors.orange.shade800,
    };

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          constraints: const BoxConstraints(minWidth: 60, maxWidth: 200),
          child: CustomPaint(
            painter: BubblePainter(
              bubbleColor: bubbleColor,
              borderColor: borderColor,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 6),
              child: showContent
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LLMの返信の場合はアイコンを表示
                        if (displayKind == BubbleDisplayKind.landReply) ...[
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.purple.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            post.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight:
                                  displayKind == BubbleDisplayKind.landReply
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                              fontStyle:
                                  displayKind == BubbleDisplayKind.landReply
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final Color bubbleColor;
  final Color borderColor;

  BubblePainter({required this.bubbleColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const radius = 12.0;
    const tailWidth = 16.0;
    const tailHeight = 6.0;

    path.addRRect(
      RRect.fromLTRBR(
        0,
        0,
        size.width,
        size.height - tailHeight,
        const Radius.circular(radius),
      ),
    );

    final tailStartX = (size.width - tailWidth) / 2;
    path.moveTo(tailStartX, size.height - tailHeight);
    path.lineTo(tailStartX + tailWidth / 2, size.height);
    path.lineTo(tailStartX + tailWidth, size.height - tailHeight);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
