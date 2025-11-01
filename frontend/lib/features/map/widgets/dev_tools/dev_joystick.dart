import 'dart:async';

import 'package:codama/core/constants/config.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// 開発用ジョイスティック
///
/// 仮想位置操作のためのUI部品
/// - 円形ドラッグエリア（直径Config.joystickSize）
/// - 中央ノブ操作でOffset値を計算
/// - 操作終了時の自動センタリング
/// - 地図座標への変換とコールバック
class DevJoystick extends StatefulWidget {
  /// ジョイスティック操作時のコールバック
  final Function(LatLng newLocation) onLocationChange;

  /// 現在の仮想位置
  final LatLng currentLocation;

  const DevJoystick({
    super.key,
    required this.onLocationChange,
    required this.currentLocation,
  });

  @override
  State<DevJoystick> createState() => _DevJoystickState();
}

class _DevJoystickState extends State<DevJoystick> {
  static const double _maxDragDistance =
      (Config.joystickSize - Config.joystickKnobSize) / 2;

  Offset _knobOffset = Offset.zero;
  bool _isDragging = false;
  Timer? _movementTimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Config.joystickSize,
      height: Config.joystickSize,
      decoration: BoxDecoration(
        color: Config.customSemiTransparentBlack,
        shape: BoxShape.circle,
        border: Border.all(
          color: Config.neutralWhite.withValues(
            alpha: Config.alphaSemiTransparent,
          ),
          width: Config.borderWidthThin,
        ),
      ),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ジョイスティックの背景
            Container(
              width: Config.joystickSize,
              height: Config.joystickSize,
              decoration: BoxDecoration(
                color: Config.neutralTransparent,
                shape: BoxShape.circle,
              ),
            ),
            // 中央ノブ
            Transform.translate(
              offset: _knobOffset,
              child: Container(
                width: Config.joystickKnobSize,
                height: Config.joystickKnobSize,
                decoration: BoxDecoration(
                  color: _isDragging ? Config.brandBlueMedium : Config.neutralWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Config.neutralBlack.withValues(
                        alpha: Config.alphaSemiTransparent,
                      ),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_searching,
                  color: _isDragging ? Config.neutralWhite : Config.neutralBlack87,
                  size: Config.joystickIconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _startMovementTimer();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final center = Offset(
      Config.joystickSize / 2,
      Config.joystickSize / 2,
    );
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // 中心からの相対位置を計算
    final offset = localPosition - center;

    // 最大ドラッグ距離で制限
    final distance = offset.distance;
    final clampedOffset = distance <= _maxDragDistance
        ? offset
        : Offset.fromDirection(offset.direction, _maxDragDistance);

    setState(() {
      _knobOffset = clampedOffset;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _knobOffset = Offset.zero;
      _isDragging = false;
    });
    _stopMovementTimer();
  }

  /// ジョイスティックオフセットを地図座標変換
  void _updateVirtualLocation(Offset offset) {
    // 正規化されたオフセット（-1.0 〜 1.0の範囲）
    final normalizedX = offset.dx / _maxDragDistance;
    final normalizedY = offset.dy / _maxDragDistance;

    // 緯度・経度の変更量を計算
    // X軸: 東西方向（経度）、Y軸: 南北方向（緯度、反転）
    final deltaLng = normalizedX * Config.joystickMovementSensitivity;
    final deltaLat = -normalizedY * Config.joystickMovementSensitivity; // Y軸反転（上=北）

    // 新しい仮想位置を計算
    final newLocation = LatLng(
      widget.currentLocation.latitude + deltaLat,
      widget.currentLocation.longitude + deltaLng,
    );

    // コールバックで位置を通知
    widget.onLocationChange(newLocation);
  }

  /// 移動タイマーを開始
  void _startMovementTimer() {
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(
      Config.joystickUpdateInterval,
      (_) {
        if (_isDragging && _knobOffset != Offset.zero) {
          _updateVirtualLocation(_knobOffset);
        }
      },
    );
  }

  /// 移動タイマーを停止
  void _stopMovementTimer() {
    _movementTimer?.cancel();
    _movementTimer = null;
  }
}
