import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/location_config.dart';
import '../../map/widgets/dev_tools/dev_location_service.dart';

class LocationService {
  final DevLocationService _devLocationService = DevLocationService();

  /// 現在地を取得する（詳細ログ付き）
  Future<LatLng> getCurrentLocation() async {
    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置を優先
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        return virtualLocation;
      }
    }

    try {
      // 1. 位置サービスが有効かチェック
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return LocationConfig.defaultLocation;
      }

      // 2. 現在の権限状態をチェック
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationConfig.defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationConfig.defaultLocation;
      }

      // 3. 位置情報取得実行
      final stopwatch = Stopwatch()..start();

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationConfig.locationSettings,
      );

      stopwatch.stop();

      final location = LatLng(position.latitude, position.longitude);

      // 精度チェック

      return location;
    } catch (e) {
      return LocationConfig.defaultLocation;
    }
  }

  /// 位置情報のリアルタイムストリーム（ログ付き）
  Stream<LatLng> getLocationStream() {
    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置ストリームを返す
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        return Stream.periodic(
          const Duration(seconds: 1),
          (_) =>
              _devLocationService.getVirtualLocation() ??
              LocationConfig.defaultLocation,
        );
      }
    }

    return Geolocator.getPositionStream(
          locationSettings: LocationConfig.locationSettings,
        )
        .map((position) {
          final location = LatLng(position.latitude, position.longitude);
          return location;
        })
        .handleError((error, stackTrace) {
          return LocationConfig.defaultLocation;
        });
  }

  /// 権限状態をチェック
  Future<LocationPermission> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    return permission;
  }

  /// 位置サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
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

  /// 開発ツールが有効かチェック
  bool get isDevToolsEnabled => DevLocationService.isDevToolsEnabled;
}
