import 'package:latlong2/latlong.dart';
import 'package:openapi/openapi.dart';

/// 吹き出しの表示種別
/// - me: 自分が投稿した投稿
/// - other: ランダムに取得する他人の投稿
/// - landReply: 自分の投稿に対するLLMの返信
/// - userReply: 自分の投稿に対する他のユーザーの返信
enum BubbleDisplayKind { me, other, landReply, userReply }

/// 投稿とその画面表示上の位置情報を保持するクラス
class BubblePosition {
  final APIPostOutput post;
  final LatLng position;
  final BubbleDisplayKind displayKind;

  BubblePosition({
    required this.post,
    required this.position,
    required this.displayKind,
  });

  BubblePosition copyWith({
    APIPostOutput? post,
    LatLng? position,
    BubbleDisplayKind? displayKind,
  }) {
    return BubblePosition(
      post: post ?? this.post,
      position: position ?? this.position,
      displayKind: displayKind ?? this.displayKind,
    );
  }
}