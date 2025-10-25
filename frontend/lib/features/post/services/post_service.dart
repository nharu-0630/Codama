import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

/// 投稿サービス - API/モック両対応
class PostService {
  static const String _baseUrl = 'http://localhost:8000';
  static const bool _useApi = false; // TODO: 本番時はtrueに変更

  // モックデータ（ローカル開発用）
  final List<Post> _mockPosts = [];

  /// サービス初期化
  Future<void> initialize() async {
    if (!_useApi) {
      // モックデータ追加
      await _addDemoData();
    }
  }

  /// リソースクリーンアップ
  Future<void> dispose() async {
    if (!_useApi) {
      _mockPosts.clear();
    }
  }

  /// 投稿作成
  Future<Post> createPost({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    if (_useApi) {
      return _createPostApi(lat: lat, lng: lng, text: text, userId: userId);
    } else {
      return _createPostMock(lat: lat, lng: lng, text: text, userId: userId);
    }
  }

  /// 投稿取得
  Future<List<Post>> getAllPosts() async {
    if (_useApi) {
      return _getPostsApi();
    } else {
      return _getPostsMock();
    }
  }

  /// 投稿削除
  Future<void> deletePost(String postId) async {
    if (_useApi) {
      await _deletePostApi(postId);
    } else {
      _deletePostMock(postId);
    }
  }

  // =============
  // モック実装
  // =============

  Future<Post> _createPostMock({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    // API遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: lat,
      lng: lng,
      kind: PostKind.user,
      text: text,
      createdAt: DateTime.now(),
      userId: userId,
    );
    
    _mockPosts.add(post);
    return post;
  }

  Future<List<Post>> _getPostsMock() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_mockPosts);
  }

  void _deletePostMock(String postId) {
    _mockPosts.removeWhere((post) => post.id == postId);
  }

  Future<void> _addDemoData() async {
    await _createPostMock(
      lat: 35.4658,
      lng: 139.6201,
      text: 'こんにちは！横浜駅です',
    );
    
    await _createPostMock(
      lat: 35.4660,
      lng: 139.6205,
      text: 'この場所は人が多いですね',
    );
    
    await _createPostMock(
      lat: 35.4665,
      lng: 139.6210,
      text: '良い天気です！',
    );
  }

  // =============
  // API実装
  // =============

  Future<Post> _createPostApi({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/posts');
    
    final requestBody = {
      'lat': lat,
      'lng': lng,
      'content': text,
      'kind': 'user',
      if (userId != null) 'user_id': userId,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return _parsePostFromApi(responseData);
    } else {
      throw Exception('投稿の作成に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<Post>> _getPostsApi() async {
    final uri = Uri.parse('$_baseUrl/posts');
    
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => _parsePostFromApi(data)).toList();
    } else {
      throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }

  Future<void> _deletePostApi(String postId) async {
    final uri = Uri.parse('$_baseUrl/posts/$postId');
    
    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('投稿の削除に失敗しました: ${response.statusCode}');
    }
  }

  Post _parsePostFromApi(Map<String, dynamic> data) {
    return Post(
      id: data['id'].toString(),
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      kind: data['kind'] == 'user' ? PostKind.user : PostKind.land,
      text: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      userId: data['user_id'] as String?,
    );
  }
}