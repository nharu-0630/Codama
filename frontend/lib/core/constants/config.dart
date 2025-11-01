import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// アプリケーション全体で使用する定数設定クラス
///
/// API、位置情報、地図表示に関する設定値を集中管理する。
/// すべての設定値はコンパイル時定数として定義され、実行時に変更されない。
class Config {
  /// プライベートコンストラクタ（インスタンス化を防ぐ）
  Config._();

  // ==================== API設定 ====================

  /// バックエンドAPIのベースURL
  ///
  /// コンパイル時に環境変数 'API_BASE_URL' から取得。
  /// 未設定の場合はローカル開発サーバーを使用する。
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// HTTPリクエストで使用するUser-Agent文字列
  static const String userAgent = 'CodamaApp';

  /// APIリクエストのタイムアウト時間
  static const Duration timeout = Duration(seconds: 5);

  // ==================== 位置情報設定 ====================

  /// デフォルトの位置座標（東京駅付近）
  ///
  /// 位置情報が取得できない場合やアプリ初回起動時に使用される。
  /// 緯度: 35.658871, 経度: 139.701960
  static const LatLng defaultLocation = LatLng(35.658871, 139.701960);

  /// 位置情報の取得精度設定
  ///
  /// bestForNavigation: ナビゲーションに最適な高精度モード。
  /// バッテリー消費は増えるが、リアルタイムの位置追跡に必要な精度が得られる。
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
  );

  // ==================== 地図表示設定 ====================

  /// デフォルトのズームレベル
  ///
  /// アプリ起動時や位置リセット時に使用される。
  static const double defaultZoom = 17.0;

  /// コンパス使用時のズームレベル
  ///
  /// ユーザーが方向を確認しやすいズーム倍率。
  static const double compassZoom = 17.0;

  /// 地図の最大ズームレベル
  ///
  /// これ以上拡大できない制限値。
  static const double maxZoom = 18.0;

  /// 地図の最小ズームレベル
  ///
  /// これ以上縮小できない制限値。
  static const double minZoom = 16.0;

  /// 地図タイルのスタイルURL
  ///
  /// Stadia Mapsの水彩画風タイルを使用。
  /// プレースホルダー: {z}=ズームレベル, {x}=X座標, {y}=Y座標
  static const String styleUrl =
      'https://tiles.stadiamaps.com/tiles/stamen_watercolor/{z}/{x}/{y}.jpg';
}
