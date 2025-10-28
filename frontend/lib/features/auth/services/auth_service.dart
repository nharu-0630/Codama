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
    } catch (e) {
      // SharedPreferences が使えない場合はメモリ上の値のみ使用
      print('SharedPreferences unavailable: $e');
    }
  }

  Future<void> _saveTokens(
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
    } catch (e) {
      print('Failed to save tokens to SharedPreferences: $e');
    }
  }

  Future<bool> signup() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveTokens(
          data['access_token'],
          data['refresh_token'],
          data['user_id'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // メモリ上からクリア
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    // SharedPreferencesからも削除を試行
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
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
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          data['access_token'],
          data['refresh_token'] ?? _refreshToken!,
          data['user_id'] ?? _userId!,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  /// 認証が必要な処理を実行（自動リフレッシュ・自動サインアップ付き）
  Future<T> withAuth<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (_isAuthenticationError(e)) {
        return await _handleAuthenticationError(action);
      }
      rethrow;
    }
  }

  bool _isAuthenticationError(Object error) {
    return error is UnauthorizedException ||
        error.toString().contains('authorization') ||
        error.toString().contains('401');
  }

  Future<T> _handleAuthenticationError<T>(Future<T> Function() action) async {
    // トークンリフレッシュを試行
    if (await refreshToken()) {
      return await action();
    }

    // リフレッシュに失敗したら自動サインアップを試行
    if (await signup()) {
      return await action();
    }

    // 両方失敗した場合はエラー
    throw AuthenticationRequiredException('認証に失敗しました');
  }
}

/// 認証が必要な場合にスローされる例外
class AuthenticationRequiredException implements Exception {
  final String message;
  AuthenticationRequiredException(this.message);

  @override
  String toString() => message;
}

/// 401 Unauthorized エラー用の例外
class UnauthorizedException implements Exception {
  final String message;
  final int statusCode;

  UnauthorizedException(this.message, {this.statusCode = 401});

  @override
  String toString() => 'UnauthorizedException: $message (status: $statusCode)';
}
