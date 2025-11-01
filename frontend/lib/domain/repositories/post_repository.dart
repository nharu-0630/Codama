import '../entities/post.dart';

abstract class PostRepository {
  Future<Map<String, dynamic>> createPost({
    required double lat,
    required double lng,
    required String text,
  });
  Future<List<Post>> getPostsByLocation(double lat, double lon);
}