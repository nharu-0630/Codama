import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/create_post_response.dart';
import '../models/post.dart';

/// 投稿サービス
class PostService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  final AuthService _authService;

  PostService({required AuthService authService}) : _authService = authService;

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

    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: _authService.getAuthHeaders(),
      body: json.encode({'content': text, 'lat': lat, 'lon': lng}),
    );

    switch (response.statusCode) {
      case 200:
      case 201:
        return CreatePostResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      case 401:
        throw UnauthorizedException('認証が必要です');
      case 422:
        throw Exception('投稿データが不正です。');
      default:
        throw Exception('投稿の作成に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<Post>> _getPostsByLocationApi(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/posts?lat=$lat&lon=$lon'),
      headers: _authService.getAuthHeaders(),
    );

    switch (response.statusCode) {
      case 200:
        final responseData = json.decode(response.body);
        final List<dynamic> posts = responseData['posts'];
        return posts.map((data) => Post.fromApiResponse(data)).toList();
      case 401:
        throw UnauthorizedException('認証が必要です');
      default:
        throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }
}
