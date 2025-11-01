import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:codama/features/location/services/cell_tracking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferencesインスタンスを提供するプロバイダー
///
/// アプリケーション全体で共有されるローカルストレージへのアクセスを提供する。
/// 認証トークンやユーザー設定の永続化に使用される。
///
/// 戻り値: SharedPreferencesのインスタンス
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// LoggerServiceインスタンスを提供するプロバイダー
///
/// アプリケーション全体で統一されたログ出力機能を提供する。
/// すべてのサービスやウィジェットからこのプロバイダー経由でロガーにアクセスできる。
///
/// 戻り値: LoggerServiceのインスタンス
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

/// ApiServiceインスタンスを提供するプロバイダー
///
/// バックエンドAPIとの通信を管理するサービスを提供する。
/// SharedPreferences、Logger、設定値を注入して初期化される。
///
/// 戻り値: ApiServiceのインスタンス
final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  final sharedPreferences = await ref.read(sharedPreferencesProvider.future);
  final logger = ref.read(loggerServiceProvider);

  final apiService = ApiService(
    openApiFactory: OpenApiFactory(),
    sharedPreferences: sharedPreferences,
    logger: logger,
    baseUrl: Config.baseUrl,
    ref: ref,
  );

  logger.d('ApiServiceプロバイダー初期化完了');
  return apiService;
});

/// CellTrackingServiceインスタンスを提供するプロバイダー
///
/// ユーザーの位置に基づいてセル（エリア区分）を追跡し、
/// セル移動時の投稿データ更新を管理するサービスを提供する。
///
/// 戻り値: CellTrackingServiceのインスタンス
final cellTrackingServiceProvider = FutureProvider<CellTrackingService>((
  ref,
) async {
  final apiService = await ref.read(apiServiceProvider.future);
  final logger = ref.read(loggerServiceProvider);

  logger.d('CellTrackingServiceプロバイダー初期化完了');
  return CellTrackingService(
    apiService: apiService,
    logger: logger,
  );
});
