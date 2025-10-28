import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/logger_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> signup();
  Future<User> signIn(String username, String password);
  Future<User> refreshToken();
  Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String userId,
  );
  Map<String, String> getAuthHeaders();
  void clearTokens();
  String? get userId;
  bool get isAuthenticated;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final SharedPreferences _sharedPreferences;
  final LoggerService _logger;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  AuthRemoteDataSourceImpl({
    required ApiClient apiClient,
    required SharedPreferences sharedPreferences,
    required LoggerService logger,
  }) : _apiClient = apiClient,
       _sharedPreferences = sharedPreferences,
       _logger = logger {
    _loadStoredTokens();
  }

  Future<void> _loadStoredTokens() async {
    try {
      _accessToken = _sharedPreferences.getString(_accessTokenKey);
      _refreshToken = _sharedPreferences.getString(_refreshTokenKey);
      _userId = _sharedPreferences.getString(_userIdKey);
    } catch (e) {
      _logger.e('SharedPreferences unavailable: $e');
    }
  }

  @override
  Future<User> signup() async {
    try {
      final response = await _apiClient.signup();
      final user = User(
        id: response.userId,
        email: null, // signup response doesn't include email
        createdAt: DateTime.now(),
      );

      await saveTokens(
        response.accessToken,
        response.refreshToken,
        response.userId,
      );

      return user;
    } catch (e) {
      _logger.e('Signup error: $e');
      rethrow;
    }
  }

  @override
  Future<User> signIn(String username, String password) async {
    try {
      final request = SigninRequest(username: username, password: password);
      final response = await _apiClient.signin(request);
      final user = User(
        id: response.userId,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await saveTokens(
        response.accessToken,
        response.refreshToken,
        response.userId,
      );

      return user;
    } catch (e) {
      _logger.e('Signin error: $e');
      rethrow;
    }
  }

  @override
  Future<User> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception('Refresh token not available');
    }

    try {
      final request = RefreshRequest(refreshToken: _refreshToken!);
      final response = await _apiClient.refresh(request);

      final user = User(
        id: response.userId,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await saveTokens(
        response.accessToken,
        response.refreshToken,
        response.userId,
      );

      return user;
    } catch (e) {
      _logger.e('Token refresh error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String userId,
  ) async {
    // メモリ上に保存（必ず成功）
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;

    // SharedPreferencesにも保存を試行（失敗してもエラーにしない）
    try {
      await _sharedPreferences.setString(_accessTokenKey, accessToken);
      await _sharedPreferences.setString(_refreshTokenKey, refreshToken);
      await _sharedPreferences.setString(_userIdKey, userId);
    } catch (e) {
      _logger.e('Failed to save tokens to SharedPreferences: $e');
    }
  }

  @override
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  @override
  void clearTokens() {
    // メモリ上からクリア
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    // SharedPreferencesからも削除を試行
    _sharedPreferences.remove(_accessTokenKey);
    _sharedPreferences.remove(_refreshTokenKey);
    _sharedPreferences.remove(_userIdKey);
  }

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null;
}
