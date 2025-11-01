import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/constants/config.dart';
import 'package:codama/core/providers/logger_service_provider.dart';
import 'package:codama/core/providers/shared_preferences_provider.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
