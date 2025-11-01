import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/openapi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// バックエンドAPIとの通信を管理するサービスクラス
///
/// 認証、投稿、位置情報など、すべてのAPI呼び出しを統一的に管理する。
/// トークンの永続化、クライアントのキャッシング、エラーハンドリングを担当。
class ApiService {
  /// OpenAPIクライアントを生成するファクトリー
  final OpenApiFactory _openApiFactory;

  /// トークンなどを永続化するための共有プリファレンス
  final SharedPreferences _sharedPreferences;

  /// ログ出力用のサービス
  final LoggerService _logger;

  /// APIのベースURL
  final String _baseUrl;

  /// Riverpodのリファレンス（状態管理用）
  final Ref _ref;

  /// キャッシュされたOpenAPIクライアントインスタンス
  Openapi? _client;

  /// ApiServiceのコンストラクタ
  ///
  /// [openApiFactory] OpenAPIクライアントファクトリー
  /// [sharedPreferences] 永続化ストレージ
  /// [logger] ログサービス
  /// [baseUrl] APIのベースURL
  /// [ref] Riverpodリファレンス
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
    // ファクトリーにこのサービスを登録（エラーハンドリングで使用）
    _openApiFactory.apiService = this;
    _logger.d('ApiService初期化完了: baseUrl=$_baseUrl');
  }

  /// 保存されているアクセストークンを取得
  ///
  /// 戻り値: アクセストークン文字列、または未認証の場合はnull
  String? get accessToken => _sharedPreferences.getString('access_token');

  /// OpenAPIクライアントを取得
  ///
  /// 既にインスタンスが存在する場合はキャッシュを返し、
  /// 存在しない場合は新しいクライアントを生成してキャッシュする。
  ///
  /// 戻り値: 設定済みのOpenAPIクライアント
  Openapi get client {
    return _client ??= _openApiFactory.build(
      baseUrl: _baseUrl,
      accessToken: accessToken,
    );
  }

  /// キャッシュされているクライアントを無効化
  ///
  /// 認証トークンが変更された場合など、クライアントの再生成が必要な際に呼び出される。
  void _invalidateClient() {
    _logger.d('APIクライアントを無効化');
    _client = null;
  }

  /// ユーザーのサインアップを実行
  ///
  /// バックエンドにサインアップリクエストを送信し、取得したトークンを保存する。
  /// サインアップ成功後、認証状態を更新する。
  ///
  /// 戻り値: サインアップレスポンス（ユーザーID、トークン等を含む）
  /// 例外: サインアップに失敗した場合、Exception をスロー
  Future<SignupResponse> signUp() async {
    try {
      _logger.i('サインアップ開始');
      final response = await client.getAuthApi().signupSignupPost();

      if (response.data == null) {
        _logger.e('サインアップ失敗: レスポンスデータがnull');
        throw Exception('サインアップに失敗しました: レスポンスデータがありません');
      }

      final signupResponse = response.data!;
      _logger.d('サインアップ成功: userId=${signupResponse.userId}');

      // トークンとユーザーIDを永続化
      await _sharedPreferences.setString(
        'access_token',
        signupResponse.accessToken,
      );
      await _sharedPreferences.setString(
        'refresh_token',
        signupResponse.refreshToken,
      );
      await _sharedPreferences.setString('user_id', signupResponse.userId);
      _logger.d('認証情報を保存');

      // 新しいトークンでクライアントを再生成
      _invalidateClient();

      // 認証状態を更新
      _ref.read(authStateProvider.notifier).setAuthenticated(true);
      _logger.i('サインアップ完了: ユーザーが認証されました');

      return signupResponse;
    } catch (e) {
      _logger.e('サインアップに失敗しました', e);
      rethrow;
    }
  }

  /// ユーザーのサインアウトを実行
  ///
  /// 保存されているすべての認証情報を削除し、認証状態をクリアする。
  /// APIクライアントも無効化され、次回アクセス時に再生成される。
  ///
  /// 例外: サインアウト処理に失敗した場合、Exception をスロー
  Future<void> signOut() async {
    try {
      _logger.i('サインアウト開始');

      // 保存されているすべての認証情報を削除
      await _sharedPreferences.remove('access_token');
      await _sharedPreferences.remove('refresh_token');
      await _sharedPreferences.remove('user_id');
      _logger.d('認証情報を削除');

      // クライアントを無効化
      _invalidateClient();

      // 認証状態を未認証に更新
      _ref.read(authStateProvider.notifier).setAuthenticated(false);
      _logger.i('サインアウト完了');
    } catch (e) {
      _logger.e('サインアウトに失敗しました', e);
      rethrow;
    }
  }

  /// 現在の認証状態を確認
  ///
  /// アクセストークンの存在をチェックし、認証状態プロバイダーも更新する。
  ///
  /// 戻り値: 認証済みの場合true、未認証の場合false
  bool isAuthenticated() {
    final isAuth = accessToken != null;
    _ref.read(authStateProvider.notifier).setAuthenticated(isAuth);
    _logger.d('認証状態チェック: ${isAuth ? "認証済み" : "未認証"}');
    return isAuth;
  }

  /// 指定座標の現在地情報を取得
  ///
  /// バックエンドから指定された緯度経度に対応するエリア情報やセル情報を取得する。
  ///
  /// [lat] 緯度
  /// [lon] 経度
  /// 戻り値: 現在地情報のレスポンス、または取得失敗時はnull
  Future<CurrentResponse?> getCurrentLocation(double lat, double lon) async {
    try {
      _logger.d('現在地情報取得開始: lat=$lat, lon=$lon');
      final response = await client.getCurrentApi().getCurrentCurrentGet(
        lat: lat,
        lon: lon,
      );

      if (response.data == null) {
        _logger.w('現在地情報の取得に失敗: レスポンスデータがnull');
        return null;
      }

      _logger.d('現在地情報取得成功');
      return response.data!;
    } catch (e) {
      _logger.e('現在地情報の取得に失敗', e);
      return null;
    }
  }

  /// 新しい投稿を作成
  ///
  /// 指定された位置とテキストで新しい投稿をバックエンドに送信する。
  /// 認証が必要なエンドポイントであり、未認証の場合は例外をスローする。
  ///
  /// [lat] 投稿位置の緯度
  /// [lng] 投稿位置の経度
  /// [text] 投稿内容のテキスト
  /// 戻り値: 作成された投稿のレスポンス
  /// 例外: 未認証または作成失敗時にExceptionをスロー
  Future<CreatePostResponse> createPost({
    required double lat,
    required double lng,
    required String text,
  }) async {
    try {
      _logger.i('投稿作成開始: lat=$lat, lng=$lng');

      if (!isAuthenticated()) {
        _logger.w('投稿作成失敗: 認証されていません');
        throw Exception('認証されていません');
      }

      final request = CreatePostRequest(
        (b) => b
          ..content = text
          ..lat = lat
          ..lon = lng,
      );
      _logger.d('投稿リクエスト作成: content=${text.substring(0, text.length > 20 ? 20 : text.length)}...');

      final response = await client.getPostsApi().createPostPostsPost(
        authorization: 'Bearer $accessToken',
        createPostRequest: request,
      );

      if (response.data == null) {
        _logger.e('投稿作成失敗: レスポンスデータがnull');
        throw Exception('投稿の作成に失敗しました: レスポンスデータがありません');
      }

      _logger.i('投稿作成成功: postId=${response.data!.id}');
      return response.data!;
    } catch (e) {
      _logger.e('投稿の作成に失敗しました', e);
      rethrow;
    }
  }

  /// 現在ログイン中のユーザーIDを取得
  ///
  /// 戻り値: ユーザーID、または未認証の場合はnull
  String? getCurrentUserId() {
    final userId = _sharedPreferences.getString('user_id');
    _logger.d('現在のユーザーID: ${userId ?? "null"}');
    return userId;
  }

  /// 指定位置周辺の投稿を取得
  ///
  /// バックエンドから指定された緯度経度周辺の投稿リストを取得する。
  /// 認証が必要なエンドポイント。
  ///
  /// [lat] 緯度
  /// [lon] 経度
  /// 戻り値: 投稿リストのレスポンス
  /// 例外: 未認証または取得失敗時にExceptionをスロー
  Future<PostsResponse> getPostsByLocation(double lat, double lon) async {
    try {
      _logger.d('位置周辺の投稿取得開始: lat=$lat, lon=$lon');

      if (!isAuthenticated()) {
        _logger.w('投稿取得失敗: 認証されていません');
        throw Exception('認証されていません');
      }

      final response = await client.getPostsApi().getPostsPostsGet(
        lat: lat,
        lon: lon,
        authorization: 'Bearer $accessToken',
      );

      if (response.data == null) {
        _logger.w('投稿データの取得に失敗: ($lat, $lon), レスポンスデータがnull');
        throw Exception('投稿データの取得に失敗しました: レスポンスデータがありません');
      }

      _logger.i('投稿データ取得成功: ${response.data!.posts.length}件の投稿');
      return response.data!;
    } catch (e) {
      _logger.e('投稿データの取得に失敗: ($lat, $lon)', e);
      rethrow;
    }
  }
}

