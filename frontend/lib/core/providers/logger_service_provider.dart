import 'package:codama/core/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// LoggerServiceインスタンスを提供するプロバイダー
///
/// アプリケーション全体で統一されたログ出力機能を提供する。
/// すべてのサービスやウィジェットからこのプロバイダー経由でロガーにアクセスできる。
///
/// 戻り値: LoggerServiceのインスタンス
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});
