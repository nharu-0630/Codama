import 'package:latlong2/latlong.dart';
import '../models/post.dart';
import '../models/bubble_position.dart';

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
  /// 画面内の吹き出しを配置
  List<BubblePosition> layoutBubbles(
    List<Post> posts,
    ViewBounds viewBounds,
    String? currentUserId,
  ) {
    // 画面内の投稿のみフィルタリング
    final visiblePosts = posts.where((post) =>
        post.lat >= viewBounds.south &&
        post.lat <= viewBounds.north &&
        post.lng >= viewBounds.west &&
        post.lng <= viewBounds.east).toList();

    // BubblePosition作成（座標調整なし）
    final bubblePositions = visiblePosts.map((post) {
      final displayKind = determineDisplayKind(post, currentUserId);
      return BubblePosition(
        post: post,
        position: LatLng(post.lat, post.lng), // サーバーから受け取った座標をそのまま使用
        isVisible: true,
        displayKind: displayKind,
      );
    }).toList();
    
    return bubblePositions;
  }


  /// 表示種別を決定
  BubbleDisplayKind determineDisplayKind(Post post, String? currentUserId) {
    if (post.kind == PostKind.land) {
      return BubbleDisplayKind.land;
    }
    
    if (post.userId == currentUserId) {
      return BubbleDisplayKind.me;
    }
    
    return BubbleDisplayKind.friend;
  }

}