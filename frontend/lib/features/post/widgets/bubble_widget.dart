import 'package:flutter/material.dart';
import '../models/post.dart';

class BubbleWidget extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const BubbleWidget({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUserPost = post.kind == PostKind.user;
    final isLandMemory = post.kind == PostKind.land;

    // ユーザー投稿: 青系
    // 土地の記憶（LLM返信）: 紫系で神秘的に
    final bubbleColor = isUserPost
        ? Colors.blue.shade100
        : isLandMemory
            ? Colors.purple.shade50.withValues(alpha: 0.9)
            : Colors.green.shade100;

    final borderColor = isUserPost
        ? Colors.blue.shade400
        : isLandMemory
            ? Colors.purple.shade300
            : Colors.green.shade400;

    final textColor = isUserPost
        ? Colors.blue.shade800
        : isLandMemory
            ? Colors.purple.shade700
            : Colors.green.shade800;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            maxWidth: 200,
          ),
          child: CustomPaint(
            painter: BubblePainter(
              bubbleColor: bubbleColor,
              borderColor: borderColor,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 土地の記憶の場合はアイコンを表示
                  if (isLandMemory) ...[
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
                        fontWeight: isLandMemory ? FontWeight.w400 : FontWeight.w500,
                        fontStyle: isLandMemory ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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

  BubblePainter({
    required this.bubbleColor,
    required this.borderColor,
  });

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