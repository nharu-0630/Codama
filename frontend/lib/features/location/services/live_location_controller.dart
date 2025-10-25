import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 常時位置情報取得を管理するコントローラー
/// アプリのライフサイクルに応じて位置情報の取得を制御し、バッテリー効率を最適化
class LiveLocationController with WidgetsBindingObserver {
  static const String _logTag = 'LiveLocationController';
  static const LatLng _defaultLocation = LatLng(35.4658, 139.6201); // 横浜駅

  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  /// 位置情報更新時のコールバック
  void Function(LatLng location)? _onLocationUpdate;

  /// エラー発生時のコールバック
  void Function(Object error)? _onError;

  /// 常時位置情報取得を開始
  /// [onLocationUpdate] 位置情報が更新された時のコールバック
  /// [onError] エラーが発生した時のコールバック
  Future<void> startTracking({
    required void Function(LatLng location) onLocationUpdate,
    void Function(Object error)? onError,
  }) async {
    if (_isTracking) {
      developer.log('⚠️ 既に位置情報追跡中です', name: _logTag);
      return;
    }

    _onLocationUpdate = onLocationUpdate;
    _onError = onError;

    developer.log('🚀 常時位置情報取得開始', name: _logTag);

    // 1) 端末設定/権限チェック
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log('❌ 位置サービスが無効です', name: _logTag);
      _onError?.call('位置サービスが無効です。設定から有効にしてください。');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      developer.log('❌ 位置情報権限が拒否されています', name: _logTag);
      _onError?.call('位置情報の権限が必要です。設定から権限を許可してください。');
      return;
    }

    developer.log('✅ 権限確認完了: ${_permissionToString(permission)}', name: _logTag);

    // 2) まずは最後の既知位置を即座に反映（あれば）
    try {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final lastLocation = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
        developer.log('📍 最後の既知位置を使用: $lastLocation', name: _logTag);
        _onLocationUpdate?.call(lastLocation);
      }
    } catch (e) {
      developer.log('⚠️ 最後の既知位置取得失敗: $e', name: _logTag);
    }

    // 3) 継続的な位置情報ストリーム開始（電池効率を考慮した設定）
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // 高精度だが用途に応じて調整可能
      distanceFilter: 15, // 15m以上移動したら通知（無駄な更新を抑制）
      timeLimit: Duration(hours: 1), // 安全策として1時間で自動停止
    );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            // 同じ座標の連続通知を抑制
            .distinct(
              (previous, current) =>
                  previous.latitude == current.latitude &&
                  previous.longitude == current.longitude,
            )
            .listen(
              (Position position) {
                final location = LatLng(position.latitude, position.longitude);
                developer.log(
                  '📍 位置更新: lat=${position.latitude.toStringAsFixed(6)}, '
                  'lng=${position.longitude.toStringAsFixed(6)}, '
                  'accuracy=${position.accuracy.toStringAsFixed(1)}m',
                  name: _logTag,
                );
                _onLocationUpdate?.call(location);
              },
              onError: (error, stackTrace) {
                debugPrint('[$_logTag] ❌ 位置情報ストリームエラー: $error');
                _onError?.call(error);
              },
            );

    _isTracking = true;

    // ライフサイクル監視を開始（フォアグラウンド/バックグラウンド制御）
    WidgetsBinding.instance.addObserver(this);

    debugPrint('[$_logTag] ✅ 常時位置情報取得が開始されました');
  }

  /// 常時位置情報取得を停止
  Future<void> stopTracking() async {
    if (!_isTracking) {
      debugPrint('[$_logTag] ⚠️ 位置情報追跡は開始されていません');
      return;
    }

    debugPrint('[$_logTag] 🛑 常時位置情報取得停止');

    WidgetsBinding.instance.removeObserver(this);
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _onLocationUpdate = null;
    _onError = null;

    debugPrint('[$_logTag] ✅ 常時位置情報取得が停止されました');
  }

  /// アプリのライフサイクル変更時の処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // バックグラウンドに移行時は一時停止してバッテリーを節約
        debugPrint('[$_logTag] ⏸️ アプリがバックグラウンドに移行：位置情報取得を一時停止');
        _positionSubscription?.pause();
        break;
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰時は再開
        debugPrint('[$_logTag] ▶️ アプリがフォアグラウンドに復帰：位置情報取得を再開');
        _positionSubscription?.resume();
        break;
      case AppLifecycleState.detached:
        // アプリ終了時は完全に停止
        debugPrint('[$_logTag] 🔚 アプリ終了：位置情報取得を停止');
        stopTracking();
        break;
      case AppLifecycleState.inactive:
        // アクティブでない状態（通話中など）は継続
        debugPrint('[$_logTag] 😴 アプリが非アクティブ状態');
        break;
      case AppLifecycleState.hidden:
        // 隠れた状態では一時停止
        debugPrint('[$_logTag] 🫥 アプリが隠れた状態：位置情報取得を一時停止');
        _positionSubscription?.pause();
        break;
    }
  }

  /// 現在の追跡状態を確認
  bool get isTracking => _isTracking;

  /// デフォルト位置（横浜駅）を取得
  LatLng get defaultLocation => _defaultLocation;

  /// 権限状態を文字列に変換
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

  /// リソースのクリーンアップ
  void dispose() {
    stopTracking();
  }
}
