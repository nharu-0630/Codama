import 'package:codama/core/constants/config.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class DevLocationService {
  static final DevLocationService _instance = DevLocationService._internal();
  factory DevLocationService() => _instance;
  DevLocationService._internal();

  LatLng? _virtualLocation;

  static bool get isDevToolsEnabled {
    return kDebugMode;
  }

  void setVirtualLocation(LatLng location) {
    if (!isDevToolsEnabled) {
      return;
    }
    _virtualLocation = location;
  }

  /// 仮想位置を取得
  LatLng? getVirtualLocation() {
    if (!isDevToolsEnabled) {
      return null;
    }

    return _virtualLocation;
  }

  /// 仮想位置をクリア
  void clearVirtualLocation() {
    if (!isDevToolsEnabled) {
      return;
    }

    _virtualLocation = null;
  }

  /// 仮想位置が設定されているかチェック
  bool get hasVirtualLocation {
    return isDevToolsEnabled && _virtualLocation != null;
  }

  /// デフォルト仮想位置を設定（横浜駅）
  void setDefaultVirtualLocation() {
    if (!isDevToolsEnabled) {
      return;
    }

    setVirtualLocation(Config.defaultLocation);
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
