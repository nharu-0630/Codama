import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/location_config.dart';
import '../../map/widgets/dev_tools/dev_location_service.dart';

class LocationService {
  static const String _logTag = LocationConfig.locationServiceTag;
  final DevLocationService _devLocationService = DevLocationService();

  /// 現在地を取得する（詳細ログ付き）
  Future<LatLng> getCurrentLocation() async {
    LocationConfig.log(_logTag, '🌍 位置情報取得開始');

    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置を優先
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        LocationConfig.log(_logTag, '🎯 仮想位置を使用中: lat=${virtualLocation.latitude.toStringAsFixed(6)}, lng=${virtualLocation.longitude.toStringAsFixed(6)}');
        return virtualLocation;
      }
      LocationConfig.log(_logTag, '🛠️ 開発ツール有効、GPS位置情報を取得します');
    }

    try {
      // 1. 位置サービスが有効かチェック
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationConfig.log(_logTag, '📡 位置サービス状態: ${serviceEnabled ? "有効" : "無効"}');

      if (!serviceEnabled) {
        LocationConfig.log(_logTag, '⚠️ 位置サービスが無効のため、デフォルト位置を使用');
        return LocationConfig.defaultLocation;
      }

      // 2. 現在の権限状態をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      LocationConfig.log(_logTag, '🔐 現在の権限状態: ${LocationConfig.permissionToString(permission)}');

      if (permission == LocationPermission.denied) {
        LocationConfig.log(_logTag, '📝 位置情報権限を要求中...');
        permission = await Geolocator.requestPermission();
        LocationConfig.log(_logTag, '📝 権限要求結果: ${LocationConfig.permissionToString(permission)}');

        if (permission == LocationPermission.denied) {
          LocationConfig.log(_logTag, '❌ 位置情報権限が拒否されました。デフォルト位置を使用');
          return LocationConfig.defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        LocationConfig.log(_logTag, '🚫 位置情報権限が永続的に拒否されています。デフォルト位置を使用');
        return LocationConfig.defaultLocation;
      }

      // 3. 位置情報取得実行
      LocationConfig.log(_logTag, '📍 GPS位置情報取得中...');
      final stopwatch = Stopwatch()..start();

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationConfig.oneTimeSettings,
      );

      stopwatch.stop();

      final location = LatLng(position.latitude, position.longitude);
      LocationConfig.log(
        _logTag,
        '✅ 位置情報取得成功: lat=${position.latitude}, lng=${position.longitude}, '
        'accuracy=${position.accuracy}m, 取得時間=${stopwatch.elapsedMilliseconds}ms',
      );

      // 精度チェック
      if (position.accuracy > LocationConfig.lowAccuracyThreshold) {
        LocationConfig.log(_logTag, '⚠️ 位置精度が低い (${position.accuracy}m)');
      }

      return location;
    } catch (e, stackTrace) {
      LocationConfig.log(
        _logTag,
        '❌ 位置情報取得エラー: $e\nスタックトレース: $stackTrace',
      );
      LocationConfig.log(_logTag, '🏢 デフォルト位置（横浜駅）を使用');
      return LocationConfig.defaultLocation;
    }
  }

  /// 位置情報のリアルタイムストリーム（ログ付き）
  Stream<LatLng> getLocationStream() {
    LocationConfig.log(_logTag, '🔄 位置情報ストリーム開始');

    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置ストリームを返す
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        LocationConfig.log(_logTag, '🎯 仮想位置ストリームを開始');
        return Stream.periodic(
          const Duration(seconds: 1),
          (_) => _devLocationService.getVirtualLocation() ?? LocationConfig.defaultLocation,
        );
      }
      LocationConfig.log(_logTag, '🛠️ 開発ツール有効、GPSストリームを開始します');
    }

    return Geolocator.getPositionStream(
          locationSettings: LocationConfig.streamSettings,
        )
        .map((position) {
          final location = LatLng(position.latitude, position.longitude);
          LocationConfig.log(
            _logTag,
            '📍 ストリーム位置更新: lat=${position.latitude}, lng=${position.longitude}, '
            'accuracy=${position.accuracy}m',
          );
          return location;
        })
        .handleError((error, stackTrace) {
          LocationConfig.log(
            _logTag,
            '❌ ストリームエラー: $error',
          );
          return LocationConfig.defaultLocation;
        });
  }

  /// 権限状態をチェック
  Future<LocationPermission> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    LocationConfig.log(_logTag, '🔍 権限状態確認: ${LocationConfig.permissionToString(permission)}');
    return permission;
  }

  /// 位置サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    LocationConfig.log(_logTag, '🔍 位置サービス確認: ${enabled ? "有効" : "無効"}');
    return enabled;
  }

  /// 2点間の距離を計算
  double calculateDistance(LatLng point1, LatLng point2) {
    final distance = Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
    LocationConfig.log(_logTag, '📏 距離計算: ${distance.toStringAsFixed(2)}m');
    return distance;
  }

  /// 仮想位置を設定（開発ツール用）
  void setVirtualLocation(LatLng location) {
    _devLocationService.setVirtualLocation(location);
  }

  /// 仮想位置をクリア（開発ツール用）
  void clearVirtualLocation() {
    _devLocationService.clearVirtualLocation();
  }

  /// 開発ツールの状態をログ出力
  void logDevToolsState() {
    _devLocationService.logCurrentState();
  }

  /// 開発ツールが有効かチェック
  bool get isDevToolsEnabled => DevLocationService.isDevToolsEnabled;

}
