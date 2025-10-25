import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/location_config.dart';
import '../../map/widgets/dev_tools/dev_location_service.dart';

/// 常時位置情報取得を管理するコントローラー
/// アプリのライフサイクルに応じて位置情報の取得を制御し、バッテリー効率を最適化
class LiveLocationController with WidgetsBindingObserver {
  static const String _logTag = LocationConfig.liveLocationControllerTag;

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
    if (_isTracking) {
      LocationConfig.log(_logTag, '⚠️ 既に位置情報追跡中です');
      return;
    }

    _onLocationUpdate = onLocationUpdate;
    _onError = onError;

    LocationConfig.log(_logTag, '🚀 常時位置情報取得開始');

    // 開発ツールが有効で仮想位置が設定されている場合は仮想位置ストリームを使用
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        LocationConfig.log(_logTag, '🎯 仮想位置ストリームを開始');
        _startVirtualLocationStream();
        _isTracking = true;
        WidgetsBinding.instance.addObserver(this);
        return;
      }
      LocationConfig.log(_logTag, '🛠️ 開発ツール有効、GPSストリームを開始');
    }

    // 1) 端末設定/権限チェック
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      LocationConfig.log(_logTag, '❌ 位置サービスが無効です');
      _onError?.call('位置サービスが無効です。設定から有効にしてください。');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      LocationConfig.log(_logTag, '❌ 位置情報権限が拒否されています');
      _onError?.call('位置情報の権限が必要です。設定から権限を許可してください。');
      return;
    }

    LocationConfig.log(
      _logTag,
      '✅ 権限確認完了: ${LocationConfig.permissionToString(permission)}',
    );

    // 2) まずは最後の既知位置を即座に反映（あれば）
    try {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final lastLocation = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
        LocationConfig.log(_logTag, '📍 最後の既知位置を使用: $lastLocation');
        _onLocationUpdate?.call(lastLocation);
      }
    } catch (e) {
      LocationConfig.log(_logTag, '⚠️ 最後の既知位置取得失敗: $e');
    }

    // 3) 継続的な位置情報ストリーム開始（電池効率を考慮した設定）
    const locationSettings = LocationConfig.liveTrackingSettings;

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
                LocationConfig.log(
                  _logTag,
                  '📍 位置更新: lat=${position.latitude.toStringAsFixed(6)}, '
                  'lng=${position.longitude.toStringAsFixed(6)}, '
                  'accuracy=${position.accuracy.toStringAsFixed(1)}m',
                );
                _onLocationUpdate?.call(location);
              },
              onError: (error, stackTrace) {
                LocationConfig.log(_logTag, '❌ 位置情報ストリームエラー: $error');
                _onError?.call(error);
              },
            );

    _isTracking = true;

    // ライフサイクル監視を開始（フォアグラウンド/バックグラウンド制御）
    WidgetsBinding.instance.addObserver(this);

    LocationConfig.log(_logTag, '✅ 常時位置情報取得が開始されました');
  }

  /// 仮想位置ストリームを開始
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
            // LocationConfig.log(
            //   _logTag,
            //   '🎯 仮想位置更新: lat=${location.latitude.toStringAsFixed(6)}, '
            //   'lng=${location.longitude.toStringAsFixed(6)}',
            // );
            _onLocationUpdate?.call(location);
          },
          onError: (error) {
            LocationConfig.log(_logTag, '❌ 仮想位置ストリームエラー: $error');
            _onError?.call(error);
          },
        );
  }

  /// 常時位置情報取得を停止
  Future<void> stopTracking() async {
    if (!_isTracking) {
      LocationConfig.log(_logTag, '⚠️ 位置情報追跡は開始されていません');
      return;
    }

    LocationConfig.log(_logTag, '🛑 常時位置情報取得停止');

    WidgetsBinding.instance.removeObserver(this);
    await _positionSubscription?.cancel();
    await _virtualPositionSubscription?.cancel();
    _positionSubscription = null;
    _virtualPositionSubscription = null;
    _isTracking = false;
    _onLocationUpdate = null;
    _onError = null;

    LocationConfig.log(_logTag, '✅ 常時位置情報取得が停止されました');
  }

  /// アプリのライフサイクル変更時の処理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // バックグラウンドに移行時は一時停止してバッテリーを節約
        LocationConfig.log(_logTag, '⏸️ アプリがバックグラウンドに移行：位置情報取得を一時停止');
        _positionSubscription?.pause();
        _virtualPositionSubscription?.pause();
        break;
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰時は再開
        LocationConfig.log(_logTag, '▶️ アプリがフォアグラウンドに復帰：位置情報取得を再開');
        _positionSubscription?.resume();
        _virtualPositionSubscription?.resume();
        break;
      case AppLifecycleState.detached:
        // アプリ終了時は完全に停止
        LocationConfig.log(_logTag, '🔚 アプリ終了：位置情報取得を停止');
        stopTracking();
        break;
      case AppLifecycleState.inactive:
        // アクティブでない状態（通話中など）は継続
        LocationConfig.log(_logTag, '😴 アプリが非アクティブ状態');
        break;
      case AppLifecycleState.hidden:
        // 隠れた状態では一時停止
        LocationConfig.log(_logTag, '🫥 アプリが隠れた状態：位置情報取得を一時停止');
        _positionSubscription?.pause();
        _virtualPositionSubscription?.pause();
        break;
    }
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
