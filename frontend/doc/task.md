# 位置情報機能実装タスク

## 概要

Kodama空間SNSアプリケーションにおける位置情報機能の段階的実装ガイドです。現在地の取得・表示、ユーザー位置のトラッキング、方向表示機能を含む完全な位置情報システムを構築します。

## 実装済み機能

✅ **基本セットアップ**
- `geolocator: ^10.1.0` パッケージ追加済み
- `flutter_map_location_marker: ^10.1.0` パッケージ追加済み
- Android位置情報権限設定完了（AndroidManifest.xml）
- iOS位置情報権限設定完了（Info.plist）
- LocationService基本実装完了

## フェーズ1: 基本位置情報機能

### タスク1.1: LocationServiceの拡張
**状態**: 基本実装完了、拡張が必要

**実装内容**:
```dart
// lib/features/location/services/location_service.dart
class LocationService {
  // 実装済み：基本的な現在地取得
  // 実装済み：権限チェック
  // 実装済み：横浜駅フォールバック
  
  // 追加実装予定：
  - リアルタイム位置ストリーム最適化
  - バッテリー最適化設定
  - 位置精度レベルの動的調整
  - エラーハンドリングの詳細化
}
```

### タスク1.2: 地図画面への位置情報統合
**状態**: 部分実装、完全統合が必要

**実装コンポーネント**:
- `CurrentLocationLayer` の実装
- リアルタイム位置更新
- 現在地中心ボタン
- 位置マーカーのカスタマイズ

**技術仕様**:
```dart
CurrentLocationLayer(
  positionStream: locationService.getLocationStream(),
  style: LocationMarkerStyle(
    marker: CustomLocationMarker(),
    markerSize: Size(24, 24),
    accuracyCircleColor: Colors.blue.withOpacity(0.1),
  ),
)
```

## フェーズ2: ヘディング・方向機能

### タスク2.1: ヘディングアップ・ノースアップ機能
**状態**: 未実装

**必要パッケージ**:
- `flutter_map_location_marker` の heading 機能活用
- デバイスの方向センサー統合

**実装機能**:
1. **ノースアップモード**: 地図が常に北を上に表示
2. **ヘディングアップモード**: 地図がユーザーの向いている方向を上に表示
3. **モード切り替えボタン**: GoogleMap風のUI

**実装例**:
```dart
// 方向モードの状態管理
enum MapOrientation { north, heading }

// モード切り替え実装
void _toggleOrientation() {
  setState(() {
    _mapOrientation = _mapOrientation == MapOrientation.north 
        ? MapOrientation.heading 
        : MapOrientation.north;
  });
}

// ヘディング対応のCurrentLocationLayer
CurrentLocationLayer(
  followOnLocationUpdate: FollowOnLocationUpdate.always,
  turnOnHeadingUpdate: _mapOrientation == MapOrientation.heading 
      ? TurnOnHeadingUpdate.always 
      : TurnOnHeadingUpdate.never,
)
```

### タスク2.2: 方向表示UI実装
**状態**: 未実装

**実装コンポーネント**:
1. **コンパスウィジェット**: 現在の向きを表示
2. **方向切り替えボタン**: ヘディング⇔ノース切り替え
3. **ステータス表示**: 現在のモードを視覚的に表示

**UIレイアウト**:
```dart
// 右下に配置する制御ボタン群
Positioned(
  bottom: 16,
  right: 16,
  child: Column(
    children: [
      // コンパスボタン（ヘディング表示）
      FloatingActionButton(
        mini: true,
        onPressed: _toggleOrientation,
        child: Icon(_mapOrientation == MapOrientation.heading 
            ? Icons.explore 
            : Icons.explore_off),
      ),
      SizedBox(height: 8),
      // 現在地ボタン
      FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    ],
  ),
)
```

## フェーズ3: 位置連動機能

### タスク3.1: 位置ベース投稿システム
**状態**: 未実装

**実装内容**:
- 投稿時の現在地自動取得
- 位置精度に基づくgeohash生成
- 近隣投稿の動的取得

### タスク3.2: 友達システムとの連携
**状態**: 未実装（design.mdで定義済み）

**実装内容**:
- 15分以内の共同位置検出
- 一時的友達関係の生成
- 友達投稿の優先表示

## フェーズ4: パフォーマンス最適化

### タスク4.1: 位置更新の最適化
**実装内容**:
```dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10, // 10m移動で更新
  timeLimit: Duration(seconds: 5),
)
```

### タスク4.2: バッテリー最適化
**実装内容**:
- アプリがバックグラウンド時の位置更新頻度調整
- 不要な位置取得の停止機能
- 省電力モードでの動作最適化

## 技術的考慮事項

### 依存関係の互換性
- `flutter_map: ^5.0.0` ← 現在使用中
- `flutter_map_location_marker: ^10.1.0` ← 新規追加
- 互換性確認済み、バージョン競合なし

### 権限処理フロー
```dart
// 権限チェックフロー
1. LocationService.isLocationServiceEnabled()
2. Geolocator.checkPermission()
3. 必要に応じてGeolocator.requestPermission()
4. 拒否時は横浜駅(35.4658, 139.6201)にフォールバック
```

### エラーハンドリング戦略
- **位置サービス無効**: デフォルト位置（横浜駅）を使用
- **権限拒否**: ユーザーに説明ダイアログ表示後、デフォルト位置使用
- **タイムアウト**: 5秒でタイムアウト、キャッシュ位置またはデフォルト位置使用
- **不正確な位置**: 精度が100m以上の場合は再取得

### 位置精度レベル
```dart
// ズームレベルに応じた精度調整
double getAccuracyForZoom(double zoom) {
  if (zoom >= 16) return LocationAccuracy.best;      // ~5m
  if (zoom >= 14) return LocationAccuracy.high;      // ~10m
  if (zoom >= 12) return LocationAccuracy.medium;    // ~100m
  return LocationAccuracy.low;                        // ~1km
}
```

## テスト戦略

### 単体テスト
- LocationService の各メソッド
- 権限処理ロジック
- エラーハンドリング

### 統合テスト
- 地図表示と位置マーカーの連携
- リアルタイム位置更新
- 方向切り替え機能

### デバイステスト
- iOS/Android実機での位置精度検証
- 方向センサーの動作確認
- バッテリー消費測定

## 実装優先順位

### 高優先度（必須）
1. LocationService の完全実装
2. CurrentLocationLayer の地図統合
3. 現在地中心ボタンの実装

### 中優先度（推奨）
1. ヘディングアップ・ノースアップ機能
2. 方向表示UI
3. パフォーマンス最適化

### 低優先度（将来）
1. 詳細な位置分析機能
2. 位置履歴の保存
3. オフライン位置キャッシュ

## 注意事項

### プライバシー考慮
- 位置データの最小限取得
- ローカルストレージのみ使用（クラウド保存禁止）
- ユーザーの明示的同意後のみ位置取得

### パフォーマンス考慮
- 位置更新頻度の適切な制限
- 不要な地図再描画の防止
- メモリリークの防止

このタスク文書は、位置情報機能の段階的実装を可能にし、各フェーズでの検証と最適化を確実に行うためのガイドラインとなります。