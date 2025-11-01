import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Auth methods
  Future<SignupResponse> signUp() async {
    try {
      final response = await client.getAuthApi().signupSignupPost();

      if (response.data == null) {
        throw Exception('Failed to sign up: No response data');
      }

      final signupResponse = response.data!;

      // Save tokens
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

      return signupResponse;
    } catch (e) {
      _logger.e('Failed to sign up: $e');
      rethrow;
    }
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
      final response = await client.getCurrentApi().getCurrentCurrentGet(
        lat: lat,
        lon: lon,
      );

      if (response.data == null) {
        _logger.w('No location data received for coordinates: ($lat, $lon)');
        return null;
      }

      return response.data!;
    } catch (e) {
      _logger.e('Failed to get current location for ($lat, $lon): $e');
      return null;
    }
  }

  // Post methods
  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    try {
      if (!isAuthenticated()) {
        throw Exception('User not authenticated');
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
        throw Exception('Failed to create post: No response data');
      }

      return response.data!;
    } catch (e) {
      _logger.e('Failed to create post: $e');
      rethrow;
    }
  }

  Future<PostsResponse> getPostsByLocation(double lat, double lon) async {
    try {
      if (!isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      
      final response = await client.getPostsApi().getPostsPostsGet(
        authorization: 'Bearer $accessToken',
        lat: lat,
        lon: lon,
      );

      if (response.data == null) {
        _logger.w('No posts data received for coordinates: ($lat, $lon)');
        throw Exception('No posts data received');
      }

      return response.data!;
    } catch (e) {
      _logger.e('Failed to get posts for location ($lat, $lon): $e');
      rethrow;
    }
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final openApiFactory = ref.read(openApiFactoryProvider);
  final sharedPreferences = ref.read(sharedPreferencesProvider).value!;
  final logger = ref.read(loggerServiceProvider);

  return ApiService(
    openApiFactory: openApiFactory,
    sharedPreferences: sharedPreferences,
    logger: logger,
    baseUrl: 'http://localhost:8000',
  );
});

final openApiFactoryProvider = Provider<OpenApiFactory>((ref) {
  return OpenApiFactory();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});
