import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/location_config.dart';
import '../../map/widgets/dev_tools/dev_location_service.dart';

/// 常時位置情報取得を管理するコントローラー
/// アプリのライフサイクルに応じて位置情報の取得を制御し、バッテリー効率を最適化
class LiveLocationController with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<LatLng>? _virtualPositionSubscription;
  bool _isTracking = false;
  final DevLocationService _devLocationService = DevLocationService();

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
    if (_isTracking) return;

    _onLocationUpdate = onLocationUpdate;
    _onError = onError;

    // 開発ツールの仮想位置をチェック
    if (await _startVirtualTrackingIfEnabled()) return;

    // 位置サービスと権限をチェック
    if (!await _checkLocationPermissions()) return;

    // 最後の既知の位置情報を取得
    await _sendLastKnownPosition();

    // 位置情報ストリームを開始
    _startRealLocationStream();

    _isTracking = true;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> _startVirtualTrackingIfEnabled() async {
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        _startVirtualLocationStream();
        _isTracking = true;
        WidgetsBinding.instance.addObserver(this);
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _onError?.call('位置サービスが無効です。設定から有効にしてください。');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _onError?.call('位置情報の権限が必要です。設定から権限を許可してください。');
      return false;
    }

    return true;
  }

  Future<void> _sendLastKnownPosition() async {
    try {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final lastLocation = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
        _onLocationUpdate?.call(lastLocation);
      }
    } catch (e) {
      // 最後の既知の位置情報の取得に失敗した場合は無視して続行
    }
  }

  void _startRealLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
              locationSettings: LocationConfig.locationSettings,
            )
            .distinct(
              (previous, current) =>
                  previous.latitude == current.latitude &&
                  previous.longitude == current.longitude,
            )
            .listen(
              (Position position) {
                final location = LatLng(position.latitude, position.longitude);
                _onLocationUpdate?.call(location);
              },
              onError: (error, stackTrace) {
                _onError?.call(error);
              },
            );
  }

  void _startVirtualLocationStream() {
    _virtualPositionSubscription?.cancel();
    _virtualPositionSubscription =
        Stream.periodic(
          const Duration(seconds: 1),
          (_) =>
              _devLocationService.getVirtualLocation() ??
              LocationConfig.defaultLocation,
        ).listen(
          (location) {
            _onLocationUpdate?.call(location);
          },
          onError: (error) {
            _onError?.call(error);
          },
        );
  }

  /// 常時位置情報取得を停止
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    WidgetsBinding.instance.removeObserver(this);
    await _positionSubscription?.cancel();
    await _virtualPositionSubscription?.cancel();
    _isTracking = false;
  }

  /// アプリのライフサイクル変更時の処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // バックグラウンドに移行時は一時停止してバッテリーを節約
        _pauseLocationTracking();
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰時は再開
        _resumeLocationTracking();
      case AppLifecycleState.detached:
        // アプリ終了時は完全に停止
        stopTracking();
      case AppLifecycleState.inactive:
        // アクティブでない状態（通話中など）は継続
        break;
    }
  }

  void _pauseLocationTracking() {
    _positionSubscription?.pause();
    _virtualPositionSubscription?.pause();
  }

  void _resumeLocationTracking() {
    _positionSubscription?.resume();
    _virtualPositionSubscription?.resume();
  }

  /// 現在の追跡状態を確認
  bool get isTracking => _isTracking;

  /// デフォルト位置（横浜駅）を取得
  LatLng get defaultLocation => LocationConfig.defaultLocation;

  /// リソースのクリーンアップ
  void dispose() {
    stopTracking();
  }
}
