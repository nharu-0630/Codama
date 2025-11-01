import 'package:codama/features/map/widgets/bubble_position.dart';
import 'package:latlong2/latlong.dart';
import 'package:openapi/openapi.dart';

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
  List<APIPostOutput> _flattenPosts(List<APIPostOutput> posts) {
    final flattened = <APIPostOutput>[];
    for (final post in posts) {
      flattened.add(post);
      // 返信を展開
      if (post.replies != null && post.replies!.isNotEmpty) {
        flattened.addAll(_flattenPosts(post.replies!.toList()));
      }
    }
    return flattened;
  }

  /// 画面内の吹き出しを配置
  List<BubblePosition> layoutBubbles(
    List<APIPostOutput> posts,
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

  bool _isInViewBounds(APIPostOutput post, ViewBounds viewBounds) {
    // Extract lat/lon from location array [lat, lon]
    final location = post.location;
    final lat = location.isNotEmpty
        ? (location[0] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final lng = location.length > 1
        ? (location[1] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return lat >= viewBounds.south &&
        lat <= viewBounds.north &&
        lng >= viewBounds.west &&
        lng <= viewBounds.east;
  }

  List<APIPostOutput> _limitRegularPosts(List<APIPostOutput> visiblePosts) {
    // Note: isTemporary is not available in APIPostOutput, treat all posts as regular for now
    final limitedRegularPosts = visiblePosts.length > maxBubbleCount
        ? visiblePosts.take(maxBubbleCount).toList()
        : visiblePosts;

    return limitedRegularPosts;
  }

  BubblePosition _createBubblePosition(
    APIPostOutput post,
    String? currentUserId,
  ) {
    // Extract lat/lon from location array [lat, lon]
    final location = post.location;
    final lat = location.isNotEmpty
        ? (location[0] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final lng = location.length > 1
        ? (location[1] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return BubblePosition(
      post: post,
      position: LatLng(lat, lng),
      displayKind: determineDisplayKind(post, currentUserId),
    );
  }

  /// 表示種別を決定
  BubbleDisplayKind determineDisplayKind(
    APIPostOutput post,
    String? currentUserId,
  ) {
    // Land memory posts have null userUuid
    if (post.userUuid == null) {
      return BubbleDisplayKind.landReply;
    }

    // 親投稿の場合
    return post.userUuid == currentUserId
        ? BubbleDisplayKind.me
        : BubbleDisplayKind.other;
  }
}
