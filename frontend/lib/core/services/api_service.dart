import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/openapi_factory.dart';
import 'logger_service.dart';

class ApiService {
  final OpenApiFactory _openApiFactory;
  final SharedPreferences _sharedPreferences;
  final LoggerService _logger;
  final String _baseUrl;

  Openapi? _client;

  ApiService({
    required OpenApiFactory openApiFactory,
    required SharedPreferences sharedPreferences,
    required LoggerService logger,
    required String baseUrl,
  }) : _openApiFactory = openApiFactory,
       _sharedPreferences = sharedPreferences,
       _logger = logger,
       _baseUrl = baseUrl;

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

  Future<T> _makeApiCall<T>(
    Future<Response<T>> Function() apiCall,
    String operation, {
    bool requiresAuth = false,
  }) async {
    try {
      if (requiresAuth && !isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final response = await apiCall();

      if (response.data == null) {
        throw Exception('Failed $operation: No response data');
      }

      return response.data!;
    } catch (e) {
      _logger.e('Failed $operation: $e');
      rethrow;
    }
  }

  // Auth methods
  Future<SignupResponse> signUp() async {
    final response = await _makeApiCall(
      () => client.getAuthApi().signupSignupPost(),
      'to sign up',
    );

    // Save tokens
    await _sharedPreferences.setString('access_token', response.accessToken);
    await _sharedPreferences.setString('refresh_token', response.refreshToken);
    await _sharedPreferences.setString('user_id', response.userId);

    _invalidateClient();

    return response;
  }

  Future<void> signOut() async {
    try {
      await _sharedPreferences.remove('access_token');
      await _sharedPreferences.remove('refresh_token');
      await _sharedPreferences.remove('user_id');

      _invalidateClient();

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Failed to sign out: $e');
      rethrow;
    }
  }

  SignupResponse? getCurrentUser() {
    final accessToken = _sharedPreferences.getString('access_token');
    final refreshToken = _sharedPreferences.getString('refresh_token');
    final userId = _sharedPreferences.getString('user_id');

    if (accessToken == null || refreshToken == null || userId == null) {
      return null;
    }

    return SignupResponse(
      (b) => b
        ..accessToken = accessToken
        ..refreshToken = refreshToken
        ..userId = userId,
    );
  }

  bool isAuthenticated() {
    return accessToken != null;
  }

  // Location methods
  Future<CurrentResponse?> getCurrentLocation(double lat, double lon) async {
    try {
      return await _makeApiCall(
        () => client.getCurrentApi().getCurrentCurrentGet(lat: lat, lon: lon),
        'to get current location for ($lat, $lon)',
      );
    } catch (e) {
      _logger.w('No location data received for coordinates: ($lat, $lon)');
      return null;
    }
  }

  // Post methods
  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    final request = CreatePostRequest(
      (b) => b
        ..content = text
        ..lat = lat
        ..lon = lng,
    );

    return await _makeApiCall(
      () => client.getPostsApi().createPostPostsPost(
        authorization: 'Bearer $accessToken',
        createPostRequest: request,
      ),
      'to create post',
      requiresAuth: true,
    );
  }

  Future<PostsResponse> getPostsByLocation(double lat, double lon) async {
    return await _makeApiCall(
      () => client.getPostsApi().getPostsPostsGet(
        authorization: 'Bearer $accessToken',
        lat: lat,
        lon: lon,
      ),
      'to get posts for location ($lat, $lon)',
      requiresAuth: true,
    );
  }
}
