import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 位置情報機能の設定を一元管理するクラス
class LocationConfig {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  LocationConfig._();

  /// デフォルト位置（横浜駅）
  static const LatLng defaultLocation = LatLng(35.4658, 139.6201);

  /// 常時追跡用の設定
  static const LocationSettings liveTrackingSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 15, // 15m以上移動したら通知
    timeLimit: Duration(hours: 1), // 安全策として1時間で自動停止
  );

  /// 一回限り取得用の設定
  static const LocationSettings oneTimeSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 5),
  );

  /// LocationServiceのストリーム用設定
  static const LocationSettings streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // 10m移動で更新
    timeLimit: Duration(seconds: 5),
  );

  /// 地図の初期設定
  static const double defaultZoom = 15.0;
  static const double compassZoom = 16.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 10.0;

  /// 位置精度の警告閾値
  static const double lowAccuracyThreshold = 100.0;   // 低精度警告

  /// ログ出力用のタグ
  static const String liveLocationControllerTag = 'LiveLocationController';
  static const String locationServiceTag = 'LocationService';
  static const String mapScreenTag = 'MapScreen';


  /// 権限状態を日本語文字列に変換
  static String permissionToString(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return '拒否';
      case LocationPermission.deniedForever:
        return '永続的に拒否';
      case LocationPermission.whileInUse:
        return 'アプリ使用中のみ許可';
      case LocationPermission.always:
        return '常に許可';
      default:
        return '不明';
    }
  }

  /// 統一されたログ出力形式
  static void log(String tag, String message) {
    debugPrint('[$tag] $message');
  }
}