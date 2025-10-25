import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/post.dart';
import '../../auth/services/auth_service.dart';

/// 投稿サービス
class PostService {
  static String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  final AuthService _authService = AuthService();

  /// サービス初期化
  Future<void> initialize() async {
    // API専用のため初期化処理なし
  }

  /// リソースクリーンアップ
  Future<void> dispose() async {
    // API専用のためクリーンアップ処理なし
  }

  /// 投稿作成
  Future<Post> createPost({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    return _createPostApi(lat: lat, lng: lng, text: text, userId: userId);
  }

  /// 投稿取得
  Future<List<Post>> getAllPosts() async {
    return _getPostsApi();
  }

  /// 位置に基づく投稿取得
  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    return _getPostsByLocationApi(lat, lon);
  }

  /// 投稿削除
  Future<void> deletePost(String postId) async {
    await _deletePostApi(postId);
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
      headers: _authService.getAuthHeaders(),
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
      headers: _authService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => _parsePostFromApi(data)).toList();
    } else {
      throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<Post>> _getPostsByLocationApi(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/posts?lat=$lat&lon=$lon');
    
    final response = await http.get(
      uri,
      headers: _authService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> posts = responseData['posts'];
      return posts.map((data) => _parsePostFromApiResponse(data)).toList();
    } else {
      throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }

  Future<void> _deletePostApi(String postId) async {
    final uri = Uri.parse('$_baseUrl/posts/$postId');
    
    final response = await http.delete(
      uri,
      headers: _authService.getAuthHeaders(),
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

  Post _parsePostFromApiResponse(Map<String, dynamic> data) {
    final location = data['location'] as List?;
    return Post(
      id: data['uuid'] as String,
      lat: location != null && location.isNotEmpty && location[0] != null 
          ? (location[0] as num).toDouble() 
          : 0.0,
      lng: location != null && location.length > 1 && location[1] != null 
          ? (location[1] as num).toDouble() 
          : 0.0,
      kind: PostKind.user,
      text: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      userId: null,
    );
  }
}