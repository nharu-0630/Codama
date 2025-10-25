enum PostKind { user, land }

class Post {
  final String id;
  final double lat;
  final double lng;
  final PostKind kind;
  final String text;
  final DateTime createdAt;
  final String? userId;

  const Post({
    required this.id,
    required this.lat,
    required this.lng,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.userId,
  });

  Post copyWith({
    String? id,
    double? lat,
    double? lng,
    PostKind? kind,
    String? text,
    DateTime? createdAt,
    String? userId,
  }) {
    return Post(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}