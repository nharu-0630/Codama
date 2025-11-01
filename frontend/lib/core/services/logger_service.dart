import 'package:codama/core/constants/config.dart';
import 'package:logger/logger.dart';

/// アプリケーション全体で使用するロギングサービス
///
/// loggerパッケージをラップし、統一されたログ出力インターフェースを提供する。
/// 開発環境では詳細なログを、本番環境では必要最低限のログを出力する。
class LoggerService {
  /// 内部で使用するLoggerインスタンス
  late final Logger _logger;

  /// LoggerServiceのコンストラクタ
  ///
  /// ログの出力フォーマットとレベルを設定する。
  /// デフォルトではデバッグレベルで、カラー出力と絵文字を有効にする。
  LoggerService() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // 通常のログではメソッド呼び出しスタックを非表示
        errorMethodCount: Config.loggerErrorMethodCount, // エラー時は指定階層分のスタックトレースを表示
        lineLength: Config.loggerLineLength, // 1行あたりの最大文字数
        colors: true, // カラー出力を有効化
        printEmojis: true, // ログレベルに応じた絵文字を表示
        dateTimeFormat: DateTimeFormat.none, // 日時フォーマットは無効（デバイスのログに含まれるため）
      ),
      level: Level.debug, // デバッグレベル以上のログを出力
    );
  }

  /// デバッグレベルのログを出力
  ///
  /// 開発時のデバッグ情報を記録する際に使用。
  /// [message] ログメッセージ
  /// [error] 関連するエラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 情報レベルのログを出力
  ///
  /// 通常の動作フローや重要なイベントを記録する際に使用。
  /// [message] ログメッセージ
  /// [error] 関連するエラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 警告レベルのログを出力
  ///
  /// 潜在的な問題や注意が必要な状況を記録する際に使用。
  /// [message] ログメッセージ
  /// [error] 関連するエラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// エラーレベルのログを出力
  ///
  /// エラーや例外が発生した際に使用。スタックトレースも記録される。
  /// [message] ログメッセージ
  /// [error] 関連するエラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 任意のレベルでログを出力
  ///
  /// 特定のログレベルを動的に指定して出力する際に使用。
  /// [level] ログレベル（Level.debug, Level.info, Level.warning, Level.error等）
  /// [message] ログメッセージ
  /// [error] 関連するエラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void log(
    Level level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, message, error: error, stackTrace: stackTrace);
  }
}
