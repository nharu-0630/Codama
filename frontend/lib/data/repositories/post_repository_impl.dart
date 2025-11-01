import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/remote/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;

  PostRepositoryImpl({required PostRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    final response = await _remoteDataSource.createPost(lat, lng, text);
    return {'post': response.post, 'similar_posts': response.similarPosts};
  }

  @override
  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    return await _remoteDataSource.getPostsByLocation(lat, lon);
  }
}
