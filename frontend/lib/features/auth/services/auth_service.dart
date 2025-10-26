import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null;

  Future<void> loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      _userId = prefs.getString(_userIdKey);

      print(
        'loadStoredTokens - accessToken: ${_accessToken?.substring(0, 20)}...',
      );
      print('loadStoredTokens - isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('loadStoredTokens error: $e');
      // SharedPreferences が使えない場合はメモリ上の値のみ使用
      print('SharedPreferences unavailable, using in-memory tokens only');
    }
  }

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    String userId,
  ) async {
    // まずメモリ上に保存（必ず成功）
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;

    print(
      'Tokens saved to memory - accessToken: ${accessToken.substring(0, 20)}...',
    );

    // SharedPreferencesにも保存を試行（失敗してもエラーにしない）
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      print('Tokens saved to SharedPreferences successfully');
    } catch (e) {
      print('Failed to save tokens to SharedPreferences: $e');
      print('Tokens are still available in memory for this session');
    }
  }

  Future<bool> signup() async {
    try {
      print('Signup attempting to: $_baseUrl/signup');
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Signup response status: ${response.statusCode}');
      print('Signup response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Signup response data keys: ${data.keys.toList()}');

        await _saveTokens(
          data['access_token'],
          data['refresh_token'],
          data['user_id'],
        );
        print(
          'Signup success - access_token: ${data['access_token']?.substring(0, 20)}...',
        );
        print('Signup success - saved isAuthenticated: $isAuthenticated');
        return true;
      }
      print(
        'Signup failed with status: ${response.statusCode}, body: ${response.body}',
      );
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // まずメモリ上からクリア
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    // SharedPreferencesからも削除を試行
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      print('Tokens removed from SharedPreferences');
    } catch (e) {
      print('Failed to remove tokens from SharedPreferences: $e');
    }
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  /// リフレッシュトークンを使ってアクセストークンを更新
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      print('Refresh token not available');
      return false;
    }

    try {
      print('Attempting token refresh...');
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': _refreshToken}),
      );

      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          data['access_token'],
          data['refresh_token'] ??
              _refreshToken!, // fallback to existing refresh token
          data['user_id'] ?? _userId!, // fallback to existing user_id
        );
        print('Token refresh success');
        return true;
      }
      print('Token refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  /// 認証が必要な処理を実行（自動リフレッシュ付き）
  Future<T> withAuth<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      // 認証エラーの場合、リフレッシュを試行
      if (e.toString().contains('authorization') ||
          e.toString().contains('401')) {
        print('Authentication error detected, attempting refresh...');
        final refreshSuccess = await refreshToken();

        if (refreshSuccess) {
          print('Token refreshed, retrying action...');
          return await action();
        } else {
          print('Token refresh failed, authentication required');
          throw AuthenticationRequiredException('認証が必要です');
        }
      }
      rethrow;
    }
  }
}

/// 認証が必要な場合にスローされる例外
class AuthenticationRequiredException implements Exception {
  final String message;
  AuthenticationRequiredException(this.message);

  @override
  String toString() => message;
}
