import '../../entities/post.dart';
import '../../repositories/post_repository.dart';

abstract class PostUseCase {
  Future<Map<String, dynamic>> createPost({
    required double lat,
    required double lng,
    required String text,
  });
  Future<List<Post>> getPostsByLocation(double lat, double lon);
}

class PostUseCaseImpl implements PostUseCase {
  final PostRepository _repository;

  PostUseCaseImpl(this._repository);

  @override
  Future<Map<String, dynamic>> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    return await _repository.createPost(lat: lat, lng: lng, text: text);
  }

  @override
  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    return await _repository.getPostsByLocation(lat, lon);
  }
}