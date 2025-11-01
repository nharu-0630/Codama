import 'dart:async';

import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:codama/features/map/widgets/dev_tools/dev_location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 常時位置情報取得を管理するコントローラー
///
/// リアルタイムで位置情報を取得し、位置変更時にコールバックを通知する。
/// アプリのライフサイクル（フォアグラウンド/バックグラウンド）に応じて
/// 位置情報の取得を制御し、バッテリー効率を最適化する。
///
/// 開発モードでは仮想位置情報にも対応し、実機なしでのテストを可能にする。
class LiveLocationController with WidgetsBindingObserver {
  /// 実際のGPS位置情報ストリームのサブスクリプション
  StreamSubscription<Position>? _positionSubscription;

  /// 開発ツール用の仮想位置情報ストリームのサブスクリプション
  StreamSubscription<LatLng>? _virtualPositionSubscription;

  /// 位置追跡が有効かどうかのフラグ
  bool _isTracking = false;

  /// 開発ツール用の仮想位置サービス
  final DevLocationService _devLocationService = DevLocationService();

  /// ログ出力用サービス
  final LoggerService _logger;

  /// 位置情報更新時のコールバック
  void Function(LatLng location)? _onLocationUpdate;

  /// エラー発生時のコールバック
  void Function(Object error)? _onError;

  /// LiveLocationControllerのコンストラクタ
  ///
  /// [logger] ログ出力用のサービス
  LiveLocationController({required LoggerService logger}) : _logger = logger {
    _logger.d('LiveLocationController初期化');
  }

  /// 常時位置情報取得を開始
  ///
  /// 位置情報の取得を開始し、位置が変更されるたびにコールバックを呼び出す。
  /// 開発ツールが有効な場合は仮想位置を、そうでなければ実際のGPS位置を使用する。
  ///
  /// [onLocationUpdate] 位置情報が更新された時のコールバック
  /// [onError] エラーが発生した時のコールバック
  Future<void> startTracking({
    required void Function(LatLng location) onLocationUpdate,
    void Function(Object error)? onError,
  }) async {
    if (_isTracking) {
      _logger.w('位置追跡は既に開始されています');
      return;
    }

    _logger.i('位置追跡を開始');
    _onLocationUpdate = onLocationUpdate;
    _onError = onError;

    // 開発ツールの仮想位置をチェック
    if (await _startVirtualTrackingIfEnabled()) {
      _logger.i('仮想位置モードで追跡開始');
      return;
    }

    // 位置サービスと権限をチェック
    if (!await _checkLocationPermissions()) {
      _logger.e('位置情報の権限チェックに失敗');
      return;
    }

    // 最後の既知の位置情報を取得
    await _sendLastKnownPosition();

    // 位置情報ストリームを開始
    _startRealLocationStream();

    _isTracking = true;
    WidgetsBinding.instance.addObserver(this);
    _logger.i('位置追跡開始完了');
  }

  /// 開発ツールが有効な場合、仮想位置追跡を開始
  ///
  /// 戻り値: 仮想位置モードで開始した場合true、そうでない場合false
  Future<bool> _startVirtualTrackingIfEnabled() async {
    if (DevLocationService.isDevToolsEnabled) {
      final virtualLocation = _devLocationService.getVirtualLocation();
      if (virtualLocation != null) {
        _logger.d('仮想位置を検出: $virtualLocation');
        _startVirtualLocationStream();
        _isTracking = true;
        WidgetsBinding.instance.addObserver(this);
        return true;
      }
    }
    return false;
  }

  /// 位置情報のサービスと権限をチェック
  ///
  /// 位置サービスの有効性と権限の状態を確認し、必要に応じて権限をリクエストする。
  ///
  /// 戻り値: 位置情報が使用可能な場合true、そうでない場合false
  Future<bool> _checkLocationPermissions() async {
    _logger.d('位置情報の権限チェック開始');

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.e('位置サービスが無効');
      _onError?.call('位置サービスが無効です。設定から有効にしてください。');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    _logger.d('現在の位置権限: $permission');

    if (permission == LocationPermission.denied) {
      _logger.i('位置権限をリクエスト');
      permission = await Geolocator.requestPermission();
      _logger.d('リクエスト後の位置権限: $permission');
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _logger.e('位置情報の権限が拒否されました');
      _onError?.call('位置情報の権限が必要です。設定から権限を許可してください。');
      return false;
    }

    _logger.i('位置情報の権限チェック成功');
    return true;
  }

  /// 最後に取得した位置情報を送信
  ///
  /// GPS初期化前に素早くおおよその位置を表示するため、
  /// 最後に記録された位置情報を取得して通知する。
  Future<void> _sendLastKnownPosition() async {
    try {
      _logger.d('最後の既知位置を取得');
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final lastLocation = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );
        _logger.i('最後の既知位置を使用: $lastLocation');
        _onLocationUpdate?.call(lastLocation);
      } else {
        _logger.d('最後の既知位置なし');
      }
    } catch (e) {
      // 最後の既知の位置情報の取得に失敗した場合は無視して続行
      _logger.w('最後の既知位置の取得に失敗', e);
    }
  }

  /// 実際のGPS位置情報ストリームを開始
  ///
  /// 連続的に位置情報を取得し、位置が変更された場合のみコールバックを呼び出す。
  void _startRealLocationStream() {
    _logger.d('実位置ストリーム開始');
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: Config.locationSettings)
            .distinct(
              (previous, current) =>
                  previous.latitude == current.latitude &&
                  previous.longitude == current.longitude,
            )
            .listen(
              (Position position) {
                final location = LatLng(position.latitude, position.longitude);
                _logger.d('位置更新: $location');
                _onLocationUpdate?.call(location);
              },
              onError: (error, stackTrace) {
                _logger.e('位置取得エラー', error);
                _onError?.call(error);
              },
            );
  }

  /// 仮想位置情報ストリームを開始（開発ツール用）
  ///
  /// 1秒ごとに仮想位置を取得し、コールバックを呼び出す。
  void _startVirtualLocationStream() {
    _logger.d('仮想位置ストリーム開始');
    _virtualPositionSubscription?.cancel();
    _virtualPositionSubscription =
        Stream.periodic(
          const Duration(seconds: 1),
          (_) =>
              _devLocationService.getVirtualLocation() ??
              Config.defaultLocation,
        ).listen(
          (location) {
            _logger.d('仮想位置更新: $location');
            _onLocationUpdate?.call(location);
          },
          onError: (error) {
            _logger.e('仮想位置取得エラー', error);
            _onError?.call(error);
          },
        );
  }

  /// 常時位置情報取得を停止
  ///
  /// 位置情報ストリームを停止し、リソースを解放する。
  /// バッテリー節約のため、不要な場合は明示的に停止すべき。
  Future<void> stopTracking() async {
    if (!_isTracking) {
      _logger.d('位置追跡は既に停止しています');
      return;
    }

    _logger.i('位置追跡を停止');
    WidgetsBinding.instance.removeObserver(this);
    await _positionSubscription?.cancel();
    await _virtualPositionSubscription?.cancel();
    _isTracking = false;
    _logger.d('位置追跡停止完了');
  }

  /// アプリのライフサイクル変更時の処理
  ///
  /// アプリがバックグラウンドに移行した際は位置追跡を一時停止し、
  /// フォアグラウンドに復帰した際は再開することでバッテリー消費を最適化する。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('アプリライフサイクル変更: $state');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // バックグラウンドに移行時は一時停止してバッテリーを節約
        _logger.i('位置追跡を一時停止（バックグラウンド）');
        _pauseLocationTracking();
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰時は再開
        _logger.i('位置追跡を再開（フォアグラウンド）');
        _resumeLocationTracking();
      case AppLifecycleState.detached:
        // アプリ終了時は完全に停止
        _logger.i('位置追跡を完全停止（アプリ終了）');
        stopTracking();
      case AppLifecycleState.inactive:
        // アクティブでない状態（通話中など）は継続
        _logger.d('アプリ非アクティブ（位置追跡継続）');
        break;
    }
  }

  /// 位置追跡を一時停止（バックグラウンド時）
  void _pauseLocationTracking() {
    _positionSubscription?.pause();
    _virtualPositionSubscription?.pause();
  }

  /// 位置追跡を再開（フォアグラウンド復帰時）
  void _resumeLocationTracking() {
    _positionSubscription?.resume();
    _virtualPositionSubscription?.resume();
  }

  /// 現在の追跡状態を確認
  ///
  /// 戻り値: 追跡中の場合true、停止中の場合false
  bool get isTracking => _isTracking;

  /// デフォルト位置を取得
  ///
  /// 位置情報が取得できない場合のフォールバック位置。
  ///
  /// 戻り値: デフォルト位置座標
  LatLng get defaultLocation => Config.defaultLocation;

  /// リソースのクリーンアップ
  ///
  /// コントローラーを破棄する際に呼び出し、すべてのリソースを解放する。
  void dispose() {
    _logger.d('LiveLocationController破棄');
    stopTracking();
  }
}
