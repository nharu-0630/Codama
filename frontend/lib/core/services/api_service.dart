import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/openapi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

class ApiService {
  final OpenApiFactory _openApiFactory;
  final SharedPreferences _sharedPreferences;
  final LoggerService _logger;
  final String _baseUrl;
  final Ref _ref;

  Openapi? _client;

  ApiService({
    required OpenApiFactory openApiFactory,
    required SharedPreferences sharedPreferences,
    required LoggerService logger,
    required String baseUrl,
    required Ref ref,
  }) : _openApiFactory = openApiFactory,
       _sharedPreferences = sharedPreferences,
       _logger = logger,
       _baseUrl = baseUrl,
       _ref = ref {
    _openApiFactory.apiService = this;
  }

  String? get accessToken => _sharedPreferences.getString('access_token');

  Openapi get client {
    return _client ??= _openApiFactory.build(
      baseUrl: _baseUrl,
      accessToken: accessToken,
    );
  }

  void _invalidateClient() {
    _client = null;
  }

  Future<SignupResponse> signUp() async {
    try {
      final response = await client.getAuthApi().signupSignupPost();
      if (response.data == null) {
        throw Exception('サインアップに失敗しました: レスポンスデータがありません');
      }

      final signupResponse = response.data!;
      await _sharedPreferences.setString(
        'access_token',
        signupResponse.accessToken,
      );
      await _sharedPreferences.setString(
        'refresh_token',
        signupResponse.refreshToken,
      );
      await _sharedPreferences.setString('user_id', signupResponse.userId);
      _invalidateClient();

      _ref.read(authStateProvider.notifier).setAuthenticated(true);
      return signupResponse;
    } catch (e) {
      _logger.e('サインアップに失敗しました: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _sharedPreferences.remove('access_token');
      await _sharedPreferences.remove('refresh_token');
      await _sharedPreferences.remove('user_id');
      _invalidateClient();

      _ref.read(authStateProvider.notifier).setAuthenticated(false);
      _logger.i('サインアウトしました');
    } catch (e) {
      _logger.e('サインアウトに失敗しました: $e');
      rethrow;
    }
  }

  bool isAuthenticated() {
    final isAuth = accessToken != null;
    _ref.read(authStateProvider.notifier).setAuthenticated(isAuth);
    return isAuth;
  }

  Future<CurrentResponse?> getCurrentLocation(double lat, double lon) async {
    try {
      final response = await client.getCurrentApi().getCurrentCurrentGet(
        lat: lat,
        lon: lon,
      );
      if (response.data == null) {
        _logger.w('現在地情報の取得に失敗しました: レスポンスデータがありません');
        return null;
      }

      return response.data!;
    } catch (e) {
      _logger.e('現在地情報の取得に失敗しました: $e');
      return null;
    }
  }

  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    try {
      if (!isAuthenticated()) {
        throw Exception('認証されていません');
      }

      final request = CreatePostRequest(
        (b) => b
          ..content = text
          ..lat = lat
          ..lon = lng,
      );

      final response = await client.getPostsApi().createPostPostsPost(
        authorization: 'Bearer $accessToken',
        createPostRequest: request,
      );
      if (response.data == null) {
        throw Exception('投稿の作成に失敗しました: レスポンスデータがありません');
      }

      return response.data!;
    } catch (e) {
      _logger.e('投稿の作成に失敗しました: $e');
      rethrow;
    }
  }

  String? getCurrentUserId() {
    return _sharedPreferences.getString('user_id');
  }

  Future<PostsResponse> getPostsByLocation(double lat, double lon) async {
    try {
      if (!isAuthenticated()) {
        throw Exception('認証されていません');
      }

      final response = await client.getPostsApi().getPostsPostsGet(
        lat: lat,
        lon: lon,
        authorization: 'Bearer $accessToken',
      );

      if (response.data == null) {
        _logger.w('投稿データの取得に失敗しました: ($lat, $lon)');
        throw Exception('投稿データの取得に失敗しました: レスポンスデータがありません');
      }

      return response.data!;
    } catch (e) {
      _logger.e('投稿データの取得に失敗しました: ($lat, $lon): $e');
      rethrow;
    }
  }
}

