import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for PostsApi
void main() {
  final instance = Openapi().getPostsApi();

  group(PostsApi, () {
    // Create Post
    //
    // 新しい投稿を作成
    //
    //Future<CreatePostResponse> createPostPostsPost(String authorization, CreatePostRequest createPostRequest) async
    test('test createPostPostsPost', () async {
      // TODO
    });

    // Get My Posts
    //
    // 自分の投稿一覧を取得
    //
    //Future<PostsResponse> getMyPostsPostsMeGet(String authorization) async
    test('test getMyPostsPostsMeGet', () async {
      // TODO
    });

    // Get Posts
    //
    // 現在位置の投稿一覧を取得
    //
    //Future<PostsResponse> getPostsPostsGet(num lat, num lon, String authorization) async
    test('test getPostsPostsGet', () async {
      // TODO
    });

  });
}
