# 常時位置情報追跡機能実装ログ

## 日時
2025-10-25

## 概要
地図画面における常時位置情報追跡機能の実装。画面を開いている間は継続的に現在地を取得し、手動の現在地取得ボタンをコンパスボタンに置き換え。

## 実装された機能

### 1. 常時位置情報追跡
- 画面初期化時に自動で位置情報追跡を開始
- `LiveLocationController`クラスによる位置情報ストリーム管理
- バッテリー効率を考慮したライフサイクル管理（バックグラウンド時の一時停止）

### 2. UIの変更
- 手動の「現在地取得」ボタンを削除
- FontAwesome製のコンパスアイコンボタンを追加
- コンパスボタンは現在地への移動 + 北向き調整機能

### 3. バッテリー最適化
- 15m距離フィルタによる無駄な更新の抑制
- アプリライフサイクルに応じた追跡の一時停止/再開
- 適切なリソースクリーンアップ

## 変更されたファイル

### 新規作成
1. **`lib/features/location/services/live_location_controller.dart`** (193行追加)
   - 常時位置情報追跡を管理するコントローラークラス
   - `WidgetsBindingObserver`でライフサイクル監視
   - エラーハンドリングと権限管理

2. **`lib/features/location/services/location_service.dart`** (154行追加)
   - 位置情報サービスのユーティリティクラス
   - 一回限りの位置取得とストリーム機能
   - 詳細なログ出力機能

### 既存ファイルの変更
1. **`lib/features/map/presentation/map_screen.dart`** (214行追加)
   - 自動位置追跡の開始機能追加
   - UIボタンの変更（現在地取得 → コンパス）
   - FontAwesome依存関係の追加

2. **`pubspec.yaml`** (1行追加)
   - `font_awesome_flutter: ^10.7.0`依存関係追加

3. **その他の設定ファイル**
   - `pubspec.lock`: 依存関係の更新
   - `AndroidManifest.xml`: 位置情報権限の追加
   - `Podfile.lock`: iOS依存関係の更新

## 技術的詳細

### LiveLocationController主要メソッド
- `startTracking()`: 位置追跡開始
- `stopTracking()`: 位置追跡停止
- `didChangeAppLifecycleState()`: アプリライフサイクル対応

### LocationService主要メソッド
- `getCurrentLocation()`: 一回限りの位置取得
- `getLocationStream()`: 位置情報ストリーム
- `checkPermissionStatus()`: 権限状態確認

### 設定値
- 距離フィルタ: 15m (無駄な更新を抑制)
- 精度: `LocationAccuracy.bestForNavigation`
- タイムアウト: 1時間 (安全策)

## エラーハンドリング
- 位置サービス無効時の対応
- 権限拒否時のフォールバック処理
- デフォルト位置（横浜駅）への自動切り替え
- 適切なエラーメッセージ表示

## テスト結果
- Flutter analyze: エラーなし
- 依存関係の解決: 成功
- アプリ起動: 正常

## 今後の改善案
- 位置精度に応じた更新頻度の調整
- 移動速度検知による最適化
- オフライン時の動作改善
- より詳細な位置情報統計の表示

## コミット情報
実装完了時点での変更統計:
- 8ファイル変更
- 1,087行追加, 233行削除
- 新規ファイル: 2個
- 主要機能: 常時位置追跡、コンパスボタン、バッテリー最適化