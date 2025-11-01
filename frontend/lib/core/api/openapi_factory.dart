import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openapi/openapi.dart';

/// OpenAPIクライアントを生成するファクトリークラス
///
/// DioベースのHTTPクライアントを構成し、認証、ログ、エラーハンドリングの
/// インターセプターを適用したOpenAPIクライアントインスタンスを提供する。
class OpenApiFactory {
  /// エラーハンドリングで使用するAPIサービス
  ///
  /// 401エラー時のサインアウト処理など、認証関連の処理に使用される。
  ApiService? apiService;

  /// OpenApiFactoryのコンストラクタ
  ///
  /// [apiService] エラーハンドリング用のAPIサービス（オプション）
  OpenApiFactory({this.apiService});

  /// OpenAPIクライアントを構築する
  ///
  /// 指定されたベースURLとアクセストークンでHTTPクライアントを設定し、
  /// 必要なインターセプターを追加してOpenAPIクライアントを生成する。
  ///
  /// [baseUrl] APIのベースURL
  /// [accessToken] 認証用のアクセストークン（オプション）
  /// 戻り値: 設定済みのOpenAPIクライアントインスタンス
  Openapi build({required String baseUrl, String? accessToken}) {
    // 基本的なHTTPオプションを設定
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Config.timeout, // 接続タイムアウト
      receiveTimeout: Config.timeout, // 受信タイムアウト
      headers: <String, String>{
        'Content-Type': 'application/json',
        'User-Agent': Config.userAgent,
      },
    );

    final dio = Dio(options);

    // デバッグモードではリクエスト/レスポンスの詳細ログを出力
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,  // リクエストボディをログ出力
          responseBody: true, // レスポンスボディをログ出力
        ),
      );
    }

    // アクセストークンが提供されている場合、認証インターセプターを追加
    if (accessToken != null) {
      dio.interceptors.add(_AuthInterceptor(accessToken));
    }

    // APIサービスが設定されている場合、エラーハンドリングインターセプターを追加
    if (apiService != null) {
      dio.interceptors.add(_ErrorInterceptor(apiService!));
    }

    return Openapi(dio: dio);
  }
}

/// 認証トークンをリクエストヘッダーに追加するインターセプター
///
/// すべてのHTTPリクエストにBearerトークンを自動的に付与する。
class _AuthInterceptor extends Interceptor {
  /// _AuthInterceptorのコンストラクタ
  ///
  /// [token] 認証に使用するアクセストークン
  _AuthInterceptor(this.token);

  /// 認証トークン
  String token;

  /// リクエスト送信前にAuthorizationヘッダーを追加
  ///
  /// [options] リクエストオプション
  /// [handler] インターセプターハンドラー
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bearer認証スキームでトークンを追加
    options.headers['Authorization'] = 'Bearer $token';
    return super.onRequest(options, handler);
  }
}

/// APIエラーをハンドリングするインターセプター
///
/// 特定のHTTPステータスコードに応じて適切な処理を実行する。
/// 現在は401 Unauthorizedエラー時の自動サインアウトに対応。
class _ErrorInterceptor extends Interceptor {
  /// _ErrorInterceptorのコンストラクタ
  ///
  /// [apiService] エラーハンドリングで使用するAPIサービス
  _ErrorInterceptor(this.apiService);

  /// エラーハンドリング用のAPIサービス
  final ApiService apiService;

  /// エラー発生時の処理
  ///
  /// 401エラーの場合は認証トークンが無効と判断し、自動的にサインアウトする。
  ///
  /// [err] Dioの例外オブジェクト
  /// [handler] エラーハンドラー
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 Unauthorized: 認証トークンが無効または期限切れ
    if (err.response?.statusCode == 401) {
      apiService.signOut(); // 自動サインアウト
    }
    handler.next(err); // 次のインターセプターまたは呼び出し元にエラーを伝播
  }
}
