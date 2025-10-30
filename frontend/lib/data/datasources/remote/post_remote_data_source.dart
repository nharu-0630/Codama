import '../../../../core/logging/logger_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../domain/entities/post.dart';

abstract class PostRemoteDataSource {
  Future<CreatePostResponse> createPost(double lat, double lng, String text);
  Future<List<Post>> getPostsByLocation(double lat, double lon);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient _apiClient;
  final LoggerService _logger;

  PostRemoteDataSourceImpl({
    required ApiClient apiClient,
    required LoggerService logger,
  }) : _apiClient = apiClient,
       _logger = logger;

  @override
  Future<CreatePostResponse> createPost(
    double lat,
    double lng,
    String text,
  ) async {
    try {
      final request = CreatePostRequest(content: text, lat: lat, lon: lng);
      final response = await _apiClient.createPost(request);
      return CreatePostResponse(
        post: response.post, // response.post is already a Post object
        similarPosts: List<Post>.from(
          response.similarPosts.map(
            (data) => data,
          ), // similarPosts are already Post objects
        ),
      );
    } catch (e) {
      _logger.e('Failed to create post: $e');
      rethrow;
    }
  }

  @override
  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    try {
      final response = await _apiClient.getPosts(lat, lon);
      return List<Post>.from(response.posts.map((data) => Post.fromJson(data)));
    } catch (e) {
      _logger.e('Failed to get posts: $e');
      rethrow;
    }
  }
}
