enum PostKind { user, land }

class Post {
  final String id;
  final double lat;
  final double lng;
  final PostKind kind;
  final String text;
  final DateTime createdAt;
  final String? userId;
  final List<Post> replies; // 土地の記憶からの返信投稿リスト
  final String? parentPostId; // この投稿がどの投稿への返信かを示すID
  final bool isTemporary; // 一時投稿かどうか（5秒で消える投稿）

  const Post({
    required this.id,
    required this.lat,
    required this.lng,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.userId,
    this.replies = const [],
    this.parentPostId,
    this.isTemporary = false,
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
    String? parentPostId,
    bool? isTemporary,
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
      parentPostId: parentPostId ?? this.parentPostId,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  factory Post.fromApiResponse(
    Map<String, dynamic> data, {
    String? parentPostId,
  }) {
    final location = data['location'] as List?;
    final postId = data['uuid'] as String;

    // 返信が土地の記憶からのものかを判定
    // APIから is_land_memory フラグが来る場合はそれを使用
    // なければ、repliesリスト内で user_id が null または 'land_memory' の場合を土地の記憶と判定
    final isLandMemory =
        data['is_land_memory'] == true ||
        (parentPostId != null && data['user_id'] == null);

    // repliesを再帰的にパース（親投稿IDを設定）
    final repliesList =
        (data['replies'] as List?)
            ?.map(
              (replyData) => Post.fromApiResponse(
                replyData as Map<String, dynamic>,
                parentPostId: postId,
              ),
            )
            .toList() ??
        [];

    return Post(
      id: postId,
      lat: location != null && location.isNotEmpty && location[0] != null
          ? (location[0] as num).toDouble()
          : 0.0,
      lng: location != null && location.length > 1 && location[1] != null
          ? (location[1] as num).toDouble()
          : 0.0,
      kind: isLandMemory ? PostKind.land : PostKind.user,
      text: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      userId: data['user_id'] as String?,
      replies: repliesList,
      parentPostId: parentPostId,
      isTemporary: false, // APIから取得した投稿は通常投稿
    );
  }
}
