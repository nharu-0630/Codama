import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// アプリケーション全体で使用する定数設定クラス
///
/// API、位置情報、地図表示、UIデザインに関する設定値を集中管理する。
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
  /// bestForNavigation: ナビゲーション最適な高精度モード。
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

  // ==================== UIテーマ設定 ====================

  /// ブランドカラー - 青系統（自分の投稿）
  static const Color brandBlueLight = Color(0xFFBBDEFB); // Colors.blue.shade100
  static const Color brandBlueMedium = Color(
    0xFF64B5F6,
  ); // Colors.blue.shade400
  static const Color brandBlueDark = Color(0xFF1565C0); // Colors.blue.shade800

  /// ブランドカラー - 緑系統（他人的投稿）
  static const Color brandGreenLight = Color(
    0xFFC8E6C9,
  ); // Colors.green.shade100
  static const Color brandGreenMedium = Color(
    0xFF81C784,
  ); // Colors.green.shade400
  static const Color brandGreenDark = Color(
    0xFF2E7D32,
  ); // Colors.green.shade800

  /// ブランドカラー - 紫系統（LLMの返信）
  static const Color brandPurpleLight = Color(
    0xE6F3E5F5,
  ); // Colors.purple.shade50 with alpha: 0.9
  static const Color brandPurpleMedium = Color(
    0xFFAB47BC,
  ); // Colors.purple.shade300
  static const Color brandPurpleIcon = Color(
    0xFFBA68C8,
  ); // Colors.purple.shade400
  static const Color brandPurpleMediumDark = Color(
    0xFF7B1FA2,
  ); // Colors.purple.shade700
  static const Color brandPurpleDark = Color(
    0xFF4A148C,
  ); // Colors.purple.shade800

  /// ブランドカラー - オレンジ系統（ユーザーの返信）
  static const Color brandOrangeLight = Color(
    0xFFFFE0B2,
  ); // Colors.orange.shade100
  static const Color brandOrange = Color(0xFFFF9800); // Colors.orange
  static const Color brandOrangeMedium = Color(
    0xFFFFB74D,
  ); // Colors.orange.shade400
  static const Color brandOrangeDark = Color(
    0xFFE65100,
  ); // Colors.orange.shade800

  ///  нейтраラルカラー
  static const Color neutralWhite = Colors.white;
  static const Color neutralRed = Color(0xFFF44336); // Colors.red
  static const Color neutralGrey = Color(0xFF9E9E9E); // Colors.grey
  static const Color neutralBlack87 = Color(
    0xDE000000,
  ); // Colors.black87 (87% alpha)
  static const Color neutralBlack = Color(0xFF000000); // Colors.black
  static const Color neutralTransparent = Color(
    0x00000000,
  ); // Colors.transparent

  /// カスタムカラー
  static const Color customLightBrown = Color(0xFFE8D5C4); // ialog背景色
  static const Color customSemiTransparentBlack = Color(0x88000000); // 半透明黒

  /// 透明度設定
  static const double alphaSemiTransparent = 0.3; // 30%透明度
  static const double alphaVeryLight = 0.1; // 10%透明度
  static const double alphaLLMReply = 0.9; // LLM返信用90%透明度

  // ==================== サイズ設定 ====================

  /// スペーシング（間隔）
  static const double spacingTiny = 6.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;

  /// アイコンサイズ
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;

  /// サイズ制約
  static const double joystickSize = 96.0;
  static const double joystickKnobSize = 36.0;
  static const double joystickIconSize = 18.0;

  /// 境界線とボーダー設定
  static const double borderWidthThin = 2.0;
  static const double borderWidthThick = 8.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;

  /// バブル（投稿）関連
  static const double bubbleMinWidth = 60.0;
  static const double bubbleMaxWidth = 200.0;
  static const double bubbleTailWidth = 16.0;
  static const double bubbleTailHeight = 8.0;
  static const double bubbleBlurRadius = 3.0;

  /// ジョイスティック設定
  static const double joystickMovementSensitivity = 0.0001; // 移動感度
  static const Duration joystickUpdateInterval = Duration(milliseconds: 50);

  // ==================== テキスト制限設定 ====================

  /// 投稿文字数制限
  static const int maxPostLength = 280;

  /// ログ設定
  static const int loggerErrorMethodCount = 8;
  static const int loggerLineLength = 120;
}
