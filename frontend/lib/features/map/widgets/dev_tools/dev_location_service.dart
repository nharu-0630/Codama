import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/location_config.dart';

/// 開発用仮想位置管理サービス
///
/// 開発時のGPS代替機能
/// - 静的仮想位置保存
/// - DEV_TOOLS環境変数による制御
/// - 本番環境での完全無効化
/// - LocationServiceとの統合
class DevLocationService {
  static const String _logTag = '[DevLocationService]';

  /// シングルトンインスタンス
  static final DevLocationService _instance = DevLocationService._internal();
  factory DevLocationService() => _instance;
  DevLocationService._internal();

  /// 仮想位置（開発時のみ使用）
  LatLng? _virtualLocation;

  /// 開発ツールが有効かチェック
  static bool get isDevToolsEnabled {
    // デバッグモード時はデフォルトで有効、DEV_TOOLS=falseで明示的に無効化可能
    if (!kDebugMode) return false;

    final devToolsValue = dotenv.env['DEV_TOOLS']?.toLowerCase();
    // DEV_TOOLSが明示的にfalseの場合のみ無効化
    return devToolsValue != 'false';
  }

  /// 仮想位置を設定
  void setVirtualLocation(LatLng location) {
    if (!isDevToolsEnabled) {
      LocationConfig.log(_logTag, '🚫 本番環境では仮想位置設定は無効化されています');
      return;
    }

    _virtualLocation = location;
    // LocationConfig.log(
    //   _logTag,
    //   '🎯 仮想位置設定: lat=${location.latitude.toStringAsFixed(6)}, '
    //   'lng=${location.longitude.toStringAsFixed(6)}'
    // );
  }

  /// 仮想位置を取得
  LatLng? getVirtualLocation() {
    if (!isDevToolsEnabled) {
      return null;
    }

    if (_virtualLocation != null) {
      LocationConfig.log(
        _logTag,
        '📍 仮想位置取得: lat=${_virtualLocation!.latitude.toStringAsFixed(6)}, '
        'lng=${_virtualLocation!.longitude.toStringAsFixed(6)}',
      );
    }

    return _virtualLocation;
  }

  /// 仮想位置をクリア
  void clearVirtualLocation() {
    if (!isDevToolsEnabled) {
      return;
    }

    _virtualLocation = null;
    LocationConfig.log(_logTag, '🗑️ 仮想位置をクリアしました');
  }

  /// 仮想位置が設定されているかチェック
  bool get hasVirtualLocation {
    return isDevToolsEnabled && _virtualLocation != null;
  }

  /// 現在の状態をログ出力
  void logCurrentState() {
    if (!isDevToolsEnabled) {
      LocationConfig.log(_logTag, '🚫 開発ツール無効（本番環境）');
      return;
    }

    if (_virtualLocation != null) {
      LocationConfig.log(
        _logTag,
        '📊 開発ツール状態: 仮想位置 '
        'lat=${_virtualLocation!.latitude.toStringAsFixed(6)}, '
        'lng=${_virtualLocation!.longitude.toStringAsFixed(6)}',
      );
    } else {
      LocationConfig.log(_logTag, '📊 開発ツール状態: 仮想位置未設定（GPS使用）');
    }
  }

  /// デフォルト仮想位置を設定（横浜駅）
  void setDefaultVirtualLocation() {
    if (!isDevToolsEnabled) {
      return;
    }

    setVirtualLocation(LocationConfig.defaultLocation);
    LocationConfig.log(_logTag, '🏢 デフォルト仮想位置（横浜駅）に設定しました');
  }

  /// 仮想位置を微調整
  void adjustVirtualLocation(double deltaLat, double deltaLng) {
    if (!isDevToolsEnabled || _virtualLocation == null) {
      return;
    }

    final newLocation = LatLng(
      _virtualLocation!.latitude + deltaLat,
      _virtualLocation!.longitude + deltaLng,
    );

    setVirtualLocation(newLocation);
  }
}
