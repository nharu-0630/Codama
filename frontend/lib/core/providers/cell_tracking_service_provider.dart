import 'package:codama/core/providers/logger_service_provider.dart';
import 'package:codama/core/providers/api_service_provider.dart';
import 'package:codama/features/location/services/cell_tracking_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  return CellTrackingService(apiService: apiService, logger: logger);
});
