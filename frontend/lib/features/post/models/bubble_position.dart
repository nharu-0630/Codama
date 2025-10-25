import 'package:latlong2/latlong.dart';
import 'post.dart';

enum BubbleDisplayKind { me, friend, land, all }

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