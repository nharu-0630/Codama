import '../entities/post.dart';

class CreatePostResponse {
  final Post post;
  final List<Post> similarPosts;

  const CreatePostResponse({
    required this.post,
    required this.similarPosts,
  });

  factory CreatePostResponse.fromApiResponse(dynamic json) {
    return CreatePostResponse(
      post: Post.fromApiResponse(json['post']),
      similarPosts: List<Post>.from(
        (json['similar_posts'] ?? []).map((x) => Post.fromApiResponse(x)),
      ),
    );
  }
}