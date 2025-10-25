import '../models/post.dart';

/// シンプルな投稿管理サービス
class SimplePostService {
  final List<Post> _posts = [];
  
  /// 指定座標に投稿を追加
  void addPost({
    required double lat,
    required double lng,
    required String text,
    PostKind kind = PostKind.user,
    String? userId,
  }) {
    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: lat,
      lng: lng,
      kind: kind,
      text: text,
      createdAt: DateTime.now(),
      userId: userId,
    );
    _posts.add(post);
  }

  /// 指定座標に複数の投稿を追加
  void addPosts(List<Post> posts) {
    _posts.addAll(posts);
  }

  /// すべての投稿を取得
  List<Post> getAllPosts() {
    return List.from(_posts);
  }

  /// 投稿をクリア
  void clearPosts() {
    _posts.clear();
  }

  /// 投稿を削除
  void removePost(String postId) {
    _posts.removeWhere((post) => post.id == postId);
  }

  /// デモ用投稿を追加
  void addDemoPosts() {
    clearPosts();
    
    // 横浜駅周辺にサンプル投稿を配置
    addPost(
      lat: 35.4658,
      lng: 139.6201,
      text: 'こんにちは！横浜駅です',
      kind: PostKind.user,
    );
    
    addPost(
      lat: 35.4660,
      lng: 139.6205,
      text: 'この場所は人が多いですね',
      kind: PostKind.land,
    );
    
    addPost(
      lat: 35.4665,
      lng: 139.6210,
      text: '良い天気です！',
      kind: PostKind.user,
    );
    
    print('デモ投稿を追加しました: ${_posts.length}件');
  }
}