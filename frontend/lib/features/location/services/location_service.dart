import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng _defaultLocation = LatLng(35.4658, 139.6201); // 横浜駅
  static const String _logTag = 'LocationService';

  /// 現在地を取得する（詳細ログ付き）
  Future<LatLng> getCurrentLocation() async {
    debugPrint('[$_logTag] 🌍 位置情報取得開始');

    try {
      // 1. 位置サービスが有効かチェック
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[$_logTag] 📡 位置サービス状態: ${serviceEnabled ? "有効" : "無効"}');

      if (!serviceEnabled) {
        debugPrint('[$_logTag] ⚠️ 位置サービスが無効のため、デフォルト位置を使用');
        return _defaultLocation;
      }

      // 2. 現在の権限状態をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[$_logTag] 🔐 現在の権限状態: ${_permissionToString(permission)}');

      if (permission == LocationPermission.denied) {
        debugPrint('[$_logTag] 📝 位置情報権限を要求中...');
        permission = await Geolocator.requestPermission();
        debugPrint('[$_logTag] 📝 権限要求結果: ${_permissionToString(permission)}');

        if (permission == LocationPermission.denied) {
          debugPrint('[$_logTag] ❌ 位置情報権限が拒否されました。デフォルト位置を使用');
          return _defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[$_logTag] 🚫 位置情報権限が永続的に拒否されています。デフォルト位置を使用');
        return _defaultLocation;
      }

      // 3. 位置情報取得実行
      debugPrint('[$_logTag] 📍 GPS位置情報取得中...');
      final stopwatch = Stopwatch()..start();

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      stopwatch.stop();

      final location = LatLng(position.latitude, position.longitude);
      debugPrint(
        '[$_logTag] ✅ 位置情報取得成功: lat=${position.latitude}, lng=${position.longitude}, '
        'accuracy=${position.accuracy}m, 取得時間=${stopwatch.elapsedMilliseconds}ms',
      );

      // 精度チェック
      if (position.accuracy > 100) {
        debugPrint('[$_logTag] ⚠️ 位置精度が低い (${position.accuracy}m)');
      }

      return location;
    } catch (e, stackTrace) {
      debugPrint(
        '[$_logTag] ❌ 位置情報取得エラー: $e\nスタックトレース: $stackTrace',
      );
      debugPrint('[$_logTag] 🏢 デフォルト位置（横浜駅）を使用');
      return _defaultLocation;
    }
  }

  /// 位置情報のリアルタイムストリーム（ログ付き）
  Stream<LatLng> getLocationStream() {
    debugPrint('[$_logTag] 🔄 位置情報ストリーム開始');

    return Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // 10m移動で更新
            timeLimit: Duration(seconds: 5),
          ),
        )
        .map((position) {
          final location = LatLng(position.latitude, position.longitude);
          debugPrint(
            '[$_logTag] 📍 ストリーム位置更新: lat=${position.latitude}, lng=${position.longitude}, '
            'accuracy=${position.accuracy}m',
          );
          return location;
        })
        .handleError((error, stackTrace) {
          debugPrint(
            '[$_logTag] ❌ ストリームエラー: $error',
          );
          return _defaultLocation;
        });
  }

  /// 権限状態をチェック
  Future<LocationPermission> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    debugPrint('[$_logTag] 🔍 権限状態確認: ${_permissionToString(permission)}');
    return permission;
  }

  /// 位置サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[$_logTag] 🔍 位置サービス確認: ${enabled ? "有効" : "無効"}');
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
    debugPrint('[$_logTag] 📏 距離計算: ${distance.toStringAsFixed(2)}m');
    return distance;
  }

  /// 権限状態を日本語文字列に変換
  String _permissionToString(LocationPermission permission) {
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

  /// 位置精度を評価
  String evaluateAccuracy(double accuracy) {
    if (accuracy <= 5) return '非常に高精度';
    if (accuracy <= 10) return '高精度';
    if (accuracy <= 50) return '中精度';
    if (accuracy <= 100) return '低精度';
    return '非常に低精度';
  }
}
