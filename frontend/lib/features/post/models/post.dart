enum PostKind { user, land }

class Post {
  final String id;
  final double lat;
  final double lng;
  final PostKind kind;
  final String text;
  final DateTime createdAt;
  final String? userId;
  final List<Post> replies;  // 土地の記憶からの返信投稿リスト

  const Post({
    required this.id,
    required this.lat,
    required this.lng,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.userId,
    this.replies = const [],
  });

  Post copyWith({
    String? id,
    double? lat,
    double? lng,
    PostKind? kind,
    String? text,
    DateTime? createdAt,
    String? userId,
    List<Post>? replies,
  }) {
    return Post(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      replies: replies ?? this.replies,
    );
  }

  factory Post.fromApiResponse(Map<String, dynamic> data) {
    final location = data['location'] as List?;

    // repliesを再帰的にパース
    final repliesList = (data['replies'] as List?)
        ?.map((replyData) => Post.fromApiResponse(replyData as Map<String, dynamic>))
        .toList() ?? [];

    return Post(
      id: data['uuid'] as String,
      lat: location != null && location.isNotEmpty && location[0] != null
          ? (location[0] as num).toDouble()
          : 0.0,
      lng: location != null && location.length > 1 && location[1] != null
          ? (location[1] as num).toDouble()
          : 0.0,
      kind: PostKind.user,
      text: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      userId: null,
      replies: repliesList,
    );
  }
}