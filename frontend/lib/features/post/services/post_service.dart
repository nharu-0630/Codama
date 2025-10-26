import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/location_config.dart';
import '../../auth/services/auth_service.dart';
import '../models/create_post_response.dart';
import '../models/post.dart';

/// 投稿サービス
class PostService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  final AuthService _authService = AuthService();

  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    return await _authService.withAuth(
      () => _createPostApi(lat: lat, lng: lng, text: text),
    );
  }

  Future<List<Post>> getPostsByLocation(double lat, double lon) async {
    return await _authService.withAuth(() => _getPostsByLocationApi(lat, lon));
  }

  Future<CreatePostResponse> _createPostApi({
    required double lat,
    required double lng,
    required String text,
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('認証が必要です。');
    }

    final uri = Uri.parse('$_baseUrl/posts');
    final requestBody = {'content': text, 'lat': lat, 'lon': lng};

    final response = await http.post(
      uri,
      headers: _authService.getAuthHeaders(),
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return CreatePostResponse.fromJson(responseData);
    } else if (response.statusCode == 422) {
      throw Exception('投稿データが不正です。');
    } else {
      throw Exception('投稿の作成に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<Post>> _getPostsByLocationApi(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/posts?lat=$lat&lon=$lon');

    LocationConfig.log('PostService', '🌐 API呼び出し: GET $uri');

    final response = await http.get(
      uri,
      headers: _authService.getAuthHeaders(),
    );

    LocationConfig.log('PostService', '📡 API応答: ステータス ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> posts = responseData['posts'];

      LocationConfig.log('PostService', '✅ 投稿取得成功: ${posts.length}件の投稿');

      return posts.map((data) => Post.fromApiResponse(data)).toList();
    } else {
      LocationConfig.log(
        'PostService',
        '❌ 投稿取得失敗: ${response.statusCode} - ${response.body}',
      );
      throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }
}
