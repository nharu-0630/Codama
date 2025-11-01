import '../../../domain/entities/post.dart';

class CreatePostResponse {
  final Post post;
  final List<Post> similarPosts;

  CreatePostResponse({required this.post, required this.similarPosts});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    return CreatePostResponse(
      post: Post.fromApiResponse(json['post']),
      similarPosts:
          (json['similar_posts'] as List?)
              ?.map((item) => Post.fromApiResponse(item))
              .toList() ??
          [],
    );
  }
}
