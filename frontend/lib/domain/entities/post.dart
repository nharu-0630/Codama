import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required double lat,
    required double lng,
    required PostKind kind,
    required String text,
    required DateTime createdAt,
    required String userId,
    @Default(false) bool isTemporary,
    @Default([]) List<Post> replies,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  factory Post.fromApiResponse(dynamic json) {
    return Post(
      id: json['id'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      kind: PostKind.values.firstWhere(
        (k) => k.name == (json['kind'] ?? 'user'),
        orElse: () => PostKind.user,
      ),
      text: json['text'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['user_id'] ?? '',
      isTemporary: json['is_temporary'] ?? false,
      replies: List<Post>.from(
        (json['replies'] ?? []).map((x) => Post.fromApiResponse(x)),
      ),
    );
  }
}

enum PostKind {
  @JsonValue('user')
  user,
  @JsonValue('land')
  land,
}
