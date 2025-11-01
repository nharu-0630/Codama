import 'dart:ui';

import 'package:codama/core/constants/config.dart';
import 'package:codama/features/map/widgets/bubble_position.dart';
import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';

class BubbleWidget extends StatelessWidget {
  final APIPostOutput post;
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
      BubbleDisplayKind.me => Config.brandBlueLight,
      BubbleDisplayKind.other => Config.brandGreenLight,
      BubbleDisplayKind.landReply => Config.brandPurpleLight,
      BubbleDisplayKind.userReply => Config.brandOrangeLight,
    };

    // Use base bubble color (isTemporary not available in APIPostOutput)
    final bubbleColor = baseBubbleColor;

    final borderColor = switch (displayKind) {
      BubbleDisplayKind.me => Config.brandBlueMedium,
      BubbleDisplayKind.other => Config.brandGreenMedium,
      BubbleDisplayKind.landReply => Config.brandPurpleMedium,
      BubbleDisplayKind.userReply => Config.brandOrangeMedium,
    };

    final textColor = switch (displayKind) {
      BubbleDisplayKind.me => Config.brandBlueDark,
      BubbleDisplayKind.other => Config.brandGreenDark,
      BubbleDisplayKind.landReply => Config.brandPurpleMediumDark,
      BubbleDisplayKind.userReply => Config.brandOrangeDark,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: Config.bubbleMinWidth,
          maxWidth: Config.bubbleMaxWidth,
        ),
        child: CustomPaint(
          painter: BubblePainter(
            bubbleColor: bubbleColor,
            borderColor: borderColor,
            borderWidth: Config.borderWidthThin,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              Config.spacingMedium,
              Config.spacingTiny,
              Config.spacingMedium,
              Config.spacingTiny,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LLMの返信の場合はアイコンを表示
                if (displayKind == BubbleDisplayKind.landReply) ...[
                  Icon(
                    Icons.auto_awesome,
                    color: Config.brandPurpleIcon,
                    size: Config.iconSizeSmall,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: showContent
                      ? Text(
                          post.content,
                          style: TextStyle(
                            color: textColor,
                            fontSize: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.fontSize,
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
                        )
                      : Stack(
                          children: [
                            Text(
                              post.content,
                              style: TextStyle(
                                color: textColor,
                                fontSize: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.fontSize,
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
                            Positioned.fill(
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: Config.bubbleBlurRadius,
                                    sigmaY: Config.bubbleBlurRadius,
                                  ),
                                  child: Container(
                                    color: Config.neutralTransparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
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
  final double borderWidth;

  BubblePainter({
    required this.bubbleColor,
    required this.borderColor,
    this.borderWidth = Config.borderWidthThin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    const radius = Config.borderRadiusMedium;
    const tailWidth = Config.bubbleTailWidth;
    const tailHeight = Config.bubbleTailHeight;

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
