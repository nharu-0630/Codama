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
    final flattenedPosts = _flattenPosts(posts);

    List<APIPostOutput> visiblePosts = [];
    try {
      visiblePosts = flattenedPosts
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      visiblePosts = flattenedPosts; // Fallback to all posts
    }

    // 通常投稿のみ最大数に制限し、一時投稿は全て含める
    final limitedPosts = _limitRegularPosts(visiblePosts);

    // BubblePosition作成
    final bubblePositions = limitedPosts
        .map((post) => _createBubblePosition(post, currentUserId))
        .toList();
    return bubblePositions;
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
    try {
      // Extract lat/lon from location array [lat, lon]
      final location = post.location;

      double lat = 0.0;
      double lng = 0.0;

      if (location.isNotEmpty) {
        final latValue = location[0];
        if (latValue != null && latValue.toString().isNotEmpty) {
          lat = double.tryParse(latValue.toString()) ?? 0.0;
        }
      }

      if (location.length > 1) {
        final lngValue = location[1];
        if (lngValue != null && lngValue.toString().isNotEmpty) {
          lng = double.tryParse(lngValue.toString()) ?? 0.0;
        }
      }

      return BubblePosition(
        post: post,
        position: LatLng(lat, lng),
        displayKind: determineDisplayKind(post, currentUserId),
      );
    } catch (e) {
      // Return default position if error occurs
      return BubblePosition(
        post: post,
        position: const LatLng(
          35.658871,
          139.70196,
        ), // Default to current location
        displayKind: determineDisplayKind(post, currentUserId),
      );
    }
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
