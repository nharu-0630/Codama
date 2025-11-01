import 'package:codama/core/constants/config.dart';
import 'package:codama/features/map/widgets/dev_tools/dev_location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final DevLocationService _devLocationService = DevLocationService();

  /// 現在地を取得する
  Future<LatLng> getCurrentLocation() async {
    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置を優先
    final virtualLocation = _getVirtualLocationIfEnabled();
    if (virtualLocation != null) {
      return virtualLocation;
    }

    try {
      // 位置サービスと権限をチェック
      if (!await _checkLocationServiceEnabled()) {
        return Config.defaultLocation;
      }

      if (!await _checkAndRequestPermission()) {
        return Config.defaultLocation;
      }

      // 位置情報を取得
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: Config.locationSettings,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return Config.defaultLocation;
    }
  }

  LatLng? _getVirtualLocationIfEnabled() {
    if (DevLocationService.isDevToolsEnabled) {
      return _devLocationService.getVirtualLocation();
    }
    return null;
  }

  Future<bool> _checkLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// 位置情報のリアルタイムストリーム
  Stream<LatLng> getLocationStream() {
    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置ストリームを返す
    final virtualLocation = _getVirtualLocationIfEnabled();
    if (virtualLocation != null) {
      return Stream.periodic(
        const Duration(seconds: 1),
        (_) =>
            _devLocationService.getVirtualLocation() ?? Config.defaultLocation,
      );
    }

    return Geolocator.getPositionStream(
          locationSettings: Config.locationSettings,
        )
        .map((position) => LatLng(position.latitude, position.longitude))
        .handleError((error, stackTrace) => Config.defaultLocation);
  }

  /// 権限状態をチェック
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// 位置サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 2点間の距離を計算
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
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
