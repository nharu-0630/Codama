import 'package:latlong2/latlong.dart';

import 'post.dart';

/// 吹き出しの表示種別
/// - me: 自分が投稿した投稿
/// - other: ランダムに取得する他人の投稿
/// - landReply: 自分の投稿に対するLLMの返信
/// - userReply: 自分の投稿に対する他のユーザーの返信
enum BubbleDisplayKind { me, other, landReply, userReply }

class BubblePosition {
  final Post post;
  final LatLng position;
  final bool isVisible;
  final BubbleDisplayKind displayKind;

  const BubblePosition({
    required this.post,
    required this.position,
    required this.isVisible,
    required this.displayKind,
  });

  BubblePosition copyWith({
    Post? post,
    LatLng? position,
    bool? isVisible,
    BubbleDisplayKind? displayKind,
  }) {
    return BubblePosition(
      post: post ?? this.post,
      position: position ?? this.position,
      isVisible: isVisible ?? this.isVisible,
      displayKind: displayKind ?? this.displayKind,
    );
  }
}
