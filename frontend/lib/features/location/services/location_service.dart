import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:codama/features/map/widgets/dev_tools/dev_location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 位置情報サービス
///
/// デバイスの現在位置を取得し、位置情報のストリームを提供する。
/// 開発ツールが有効な場合は仮想位置を優先的に使用する。
/// 権限チェックとエラーハンドリングも管理する。
class LocationService {
  /// 開発ツール用の仮想位置サービス
  final DevLocationService _devLocationService = DevLocationService();

  /// ログ出力用サービス
  final LoggerService _logger;

  /// LocationServiceのコンストラクタ
  ///
  /// [logger] ログ出力用のサービス
  LocationService({required LoggerService logger}) : _logger = logger {
    _logger.d('LocationService初期化');
  }

  /// 現在地を取得する
  ///
  /// デバイスのGPSから現在位置を取得する。
  /// 開発ツールが有効な場合は仮想位置を優先的に返す。
  /// 位置情報の取得に失敗した場合はデフォルト位置を返す。
  ///
  /// 戻り値: 現在位置の座標
  Future<LatLng> getCurrentLocation() async {
    _logger.d('現在位置取得開始');

    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置を優先
    final virtualLocation = _getVirtualLocationIfEnabled();
    if (virtualLocation != null) {
      _logger.i('仮想位置を使用: $virtualLocation');
      return virtualLocation;
    }

    try {
      // 位置サービスと権限をチェック
      if (!await _checkLocationServiceEnabled()) {
        _logger.w('位置サービスが無効、デフォルト位置を使用');
        return Config.defaultLocation;
      }

      if (!await _checkAndRequestPermission()) {
        _logger.w('位置権限が拒否、デフォルト位置を使用');
        return Config.defaultLocation;
      }

      // 位置情報を取得
      _logger.d('GPS位置情報を取得中');
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: Config.locationSettings,
      );

      final location = LatLng(position.latitude, position.longitude);
      _logger.i('現在位置取得成功: $location');
      return location;
    } catch (e) {
      _logger.e('位置情報取得失敗、デフォルト位置を使用', e);
      return Config.defaultLocation;
    }
  }

  /// 開発ツールが有効な場合、仮想位置を取得
  ///
  /// 戻り値: 仮想位置、または開発ツールが無効/未設定の場合はnull
  LatLng? _getVirtualLocationIfEnabled() {
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        _logger.d('仮想位置が設定されています');
      }
      return virtualLocation;
    }
    return null;
  }

  /// 位置サービスが有効かチェック
  ///
  /// 戻り値: 位置サービスが有効な場合true
  Future<bool> _checkLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    _logger.d('位置サービス有効状態: $enabled');
    return enabled;
  }

  /// 位置権限をチェックし、必要に応じてリクエスト
  ///
  /// 戻り値: 権限が許可されている場合true
  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    _logger.d('現在の位置権限: $permission');

    if (permission == LocationPermission.denied) {
      _logger.i('位置権限をリクエスト');
      permission = await Geolocator.requestPermission();
      _logger.d('リクエスト後の位置権限: $permission');
    }

    final granted = permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
    _logger.d('位置権限チェック結果: ${granted ? "許可" : "拒否"}');
    return granted;
  }

  /// 位置情報のリアルタイムストリーム
  ///
  /// 位置が変更されるたびに新しい座標を発行するストリームを返す。
  /// 開発ツールが有効な場合は仮想位置のストリームを返す。
  ///
  /// 戻り値: 位置情報のストリーム
  Stream<LatLng> getLocationStream() {
    _logger.d('位置情報ストリーム開始');

    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置ストリームを返す
    final virtualLocation = _getVirtualLocationIfEnabled();
    if (virtualLocation != null) {
      _logger.i('仮想位置ストリームを使用');
      return Stream.periodic(
        const Duration(seconds: 1),
        (_) =>
            _devLocationService.getVirtualLocation() ?? Config.defaultLocation,
      );
    }

    _logger.i('実位置ストリームを使用');
    return Geolocator.getPositionStream(
          locationSettings: Config.locationSettings,
        )
        .map((position) {
          final location = LatLng(position.latitude, position.longitude);
          _logger.d('位置更新: $location');
          return location;
        })
        .handleError((error, stackTrace) {
          _logger.e('位置ストリームエラー', error);
          return Config.defaultLocation;
        });
  }

  /// 権限状態をチェック
  ///
  /// 現在の位置情報権限の状態を確認する。
  ///
  /// 戻り値: 権限の状態
  Future<LocationPermission> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    _logger.d('位置権限状態: $permission');
    return permission;
  }

  /// 位置サービスが有効かチェック
  ///
  /// デバイスの位置サービス（GPS等）が有効になっているか確認する。
  ///
  /// 戻り値: 位置サービスが有効な場合true
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    _logger.d('位置サービス有効: $enabled');
    return enabled;
  }

  /// 2点間の距離を計算
  ///
  /// 2つの座標間の直線距離をメートル単位で計算する。
  ///
  /// [point1] 始点の座標
  /// [point2] 終点の座標
  /// 戻り値: 2点間の距離（メートル）
  double calculateDistance(LatLng point1, LatLng point2) {
    final distance = Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
    _logger.d('距離計算: ${distance.toStringAsFixed(2)}m');
    return distance;
  }

  /// 仮想位置を設定（開発ツール用）
  ///
  /// 開発/テスト用に任意の位置を設定する。
  ///
  /// [location] 設定する仮想位置
  void setVirtualLocation(LatLng location) {
    _logger.i('仮想位置を設定: $location');
    _devLocationService.setVirtualLocation(location);
  }

  /// 仮想位置をクリア（開発ツール用）
  ///
  /// 設定された仮想位置をクリアし、実際のGPS位置に戻す。
  void clearVirtualLocation() {
    _logger.i('仮想位置をクリア');
    _devLocationService.clearVirtualLocation();
  }

  /// 開発ツールが有効かチェック
  ///
  /// 戻り値: 開発ツールが有効な場合true
  bool get isDevToolsEnabled => DevLocationService.isDevToolsEnabled;
}
