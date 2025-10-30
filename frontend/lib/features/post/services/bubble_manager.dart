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
  static const int maxBubbleCount = 15;

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
    // 投稿と返信を展開して、画面内の投稿のみフィルタリング
    final visiblePosts =
        _flattenPosts(
            posts,
          ).where((post) => _isInViewBounds(post, viewBounds)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 通常投稿のみ最大数に制限し、一時投稿は全て含める
    final limitedPosts = _limitRegularPosts(visiblePosts);

    // BubblePosition作成
    return limitedPosts
        .map((post) => _createBubblePosition(post, currentUserId))
        .toList();
  }

  bool _isInViewBounds(Post post, ViewBounds viewBounds) {
    return post.lat >= viewBounds.south &&
        post.lat <= viewBounds.north &&
        post.lng >= viewBounds.west &&
        post.lng <= viewBounds.east;
  }

  List<Post> _limitRegularPosts(List<Post> visiblePosts) {
    final regularPosts = visiblePosts.where((p) => !p.isTemporary).toList();
    final temporaryPosts = visiblePosts.where((p) => p.isTemporary).toList();

    final limitedRegularPosts = regularPosts.length > maxBubbleCount
        ? regularPosts.take(maxBubbleCount).toList()
        : regularPosts;

    return [...limitedRegularPosts, ...temporaryPosts];
  }

  BubblePosition _createBubblePosition(Post post, String? currentUserId) {
    return BubblePosition(
      post: post,
      position: LatLng(post.lat, post.lng),
      isVisible: true,
      displayKind: determineDisplayKind(post, currentUserId),
    );
  }

  /// 表示種別を決定
  BubbleDisplayKind determineDisplayKind(Post post, String? currentUserId) {
    // 返信の場合
    if (post.parentPostId != null) {
      return post.kind == PostKind.land
          ? BubbleDisplayKind.landReply
          : BubbleDisplayKind.userReply;
    }

    // 親投稿の場合
    return post.userId == currentUserId
        ? BubbleDisplayKind.me
        : BubbleDisplayKind.other;
  }
}
