import 'package:latlong2/latlong.dart';

import '../models/bubble_position.dart';
import '../models/post.dart';

class ViewBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const ViewBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

class BubbleManager {
  static const int maxBubbleCount = 30;
  static const double bubbleWidth = 200.0;
  static const double horizontalPadding = 20.0; // 左右のpadding合計
  static const double iconWidth = 22.0; // 土地の記憶アイコン + spacing
  static const double fontSize = 14.0;
  static const double lineHeight = 18.0;
  static const double baseHeight = 30.0; // 1行の基本高さ（padding含む）

  /// テキストから吹き出しの高さを計算
  double calculateBubbleHeight(Post post) {
    final isLandMemory = post.kind == PostKind.land;
    final effectiveWidth =
        bubbleWidth - horizontalPadding - (isLandMemory ? iconWidth : 0);

    // 1行あたりの文字数を推定（日本語は文字幅が大きいため少なめに）
    final charsPerLine = (effectiveWidth / (fontSize * 0.7)).floor();

    // 改行で分割して実際の行を考慮
    final lines = post.text.split('\n');

    // 各行が何行分になるか計算
    int totalLines = 0;
    for (final line in lines) {
      if (line.isEmpty) {
        totalLines += 1; // 空行も1行としてカウント
      } else {
        totalLines += (line.length / charsPerLine).ceil();
      }
    }

    final estimatedLines = totalLines.clamp(1, 3); // maxLines=3

    // 高さを計算: 基本高さ + (追加行数 × 行の高さ)
    final height = baseHeight + ((estimatedLines - 1) * lineHeight);

    print(
      '🎯 [BubbleManager] kind=${post.kind}, textLen=${post.text.length}, actualLines=${lines.length}, estimatedLines=$estimatedLines, height=$height, text="${post.text.substring(0, post.text.length > 20 ? 20 : post.text.length).replaceAll('\n', '\\n')}..."',
    );

    return height;
  }

  /// 投稿と返信を展開してフラット化
  List<Post> _flattenPosts(List<Post> posts) {
    final flattened = <Post>[];
    for (final post in posts) {
      flattened.add(post);
      // 返信を展開
      if (post.replies.isNotEmpty) {
        flattened.addAll(_flattenPosts(post.replies));
      }
    }
    return flattened;
  }

  /// 画面内の吹き出しを配置
  List<BubblePosition> layoutBubbles(
    List<Post> posts,
    ViewBounds viewBounds,
    String? currentUserId,
  ) {
    // 投稿と返信を展開
    final allPosts = _flattenPosts(posts);

    // 画面内の投稿のみフィルタリング
    final visiblePosts = allPosts
        .where(
          (post) =>
              post.lat >= viewBounds.south &&
              post.lat <= viewBounds.north &&
              post.lng >= viewBounds.west &&
              post.lng <= viewBounds.east,
        )
        .toList();

    // 投稿を作成日時でソート（新しい順）
    visiblePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 通常投稿と一時投稿を分離
    final regularPosts = visiblePosts.where((p) => !p.isTemporary).toList();
    final temporaryPosts = visiblePosts.where((p) => p.isTemporary).toList();

    // 通常投稿のみ最大数に制限
    final limitedRegularPosts = regularPosts.length > maxBubbleCount
        ? regularPosts.take(maxBubbleCount).toList()
        : regularPosts;

    // 制限された通常投稿と全ての一時投稿を結合
    final limitedPosts = [...limitedRegularPosts, ...temporaryPosts];

    // BubblePosition作成（座標調整なし）
    final bubblePositions = limitedPosts.map((post) {
      final displayKind = determineDisplayKind(post, currentUserId);
      final height = calculateBubbleHeight(post);
      return BubblePosition(
        post: post,
        position: LatLng(post.lat, post.lng), // サーバーから受け取った座標をそのまま使用
        isVisible: true,
        displayKind: displayKind,
        height: height,
      );
    }).toList();

    return bubblePositions;
  }

  /// 表示種別を決定
  BubbleDisplayKind determineDisplayKind(Post post, String? currentUserId) {
    // 返信の場合
    if (post.parentPostId != null) {
      // LLMの返信
      if (post.kind == PostKind.land) {
        return BubbleDisplayKind.landReply;
      }
      // 他のユーザーの返信
      return BubbleDisplayKind.userReply;
    }

    // 親投稿の場合
    // 自分の投稿
    if (post.userId == currentUserId) {
      return BubbleDisplayKind.me;
    }

    // 他人の投稿
    return BubbleDisplayKind.other;
  }
}
