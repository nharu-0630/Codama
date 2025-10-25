import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/post.dart';
import '../models/create_post_response.dart';
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
  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    return await _authService.withAuth(() => 
      _createPostApi(lat: lat, lng: lng, text: text, userId: userId)
    );
  }

  /// 投稿取得
  Future<List<Post>> getAllPosts() async {
    return _getPostsApi();
  }

  /// 位置に基づく投稿取得
  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    return await _authService.withAuth(() => 
      _getPostsByLocationApi(lat, lon)
    );
  }

  /// 投稿削除
  Future<void> deletePost(String postId) async {
    await _deletePostApi(postId);
  }

  // =============
  // API実装
  // =============

  Future<CreatePostResponse> _createPostApi({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    // 認証状態を確認
    if (!_authService.isAuthenticated) {
      print('投稿API失敗 - 認証されていません');
      throw Exception('認証が必要です。再度サインアップしてください。');
    }

    final uri = Uri.parse('$_baseUrl/posts');
    
    final requestBody = {
      'content': text,
      'lat': lat,
      'lon': lng,
    };

    final headers = _authService.getAuthHeaders();
    print('投稿API - リクエストヘッダー: $headers');
    print('投稿API - 認証状態: isAuthenticated=${_authService.isAuthenticated}, token=${_authService.accessToken?.substring(0, 20)}...');

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('=== 投稿作成成功 - APIレスポンス ===');
      print('ステータスコード: ${response.statusCode}');
      print('レスポンスボディ（RAW）:');
      print(response.body);
      print('=====================================');

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      print('パース後のデータ構造:');
      print('post: ${responseData['post']}');
      print('similar_posts: ${responseData['similar_posts']}');
      print('=====================================');

      return CreatePostResponse.fromJson(responseData);
    } else {
      print('投稿API失敗 - ステータス: ${response.statusCode}');
      print('投稿API失敗 - レスポンス: ${response.body}');
      print('投稿API失敗 - リクエスト: ${json.encode(requestBody)}');
      print('投稿API失敗 - ヘッダー: ${_authService.getAuthHeaders()}');
      
      if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        if (errorData['detail'] != null) {
          final details = errorData['detail'] as List;
          for (final detail in details) {
            if (detail['loc'] != null && detail['loc'].contains('authorization')) {
              throw Exception('認証エラー: Authorizationヘッダーが必要です。再度サインアップしてください。');
            }
          }
        }
      }
      
      throw Exception('投稿の作成に失敗しました: ${response.statusCode} - ${response.body}');
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
      return responseData.map((data) => Post.fromApiResponse(data)).toList();
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
      return posts.map((data) => Post.fromApiResponse(data)).toList();
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

}