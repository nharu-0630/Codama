# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) にガイダンスを提供します。

## プロジェクト概要

**Kodama**は、会話をユーザーではなく物理的な場所に結びつける空間SNS (ソーシャルネットワーキングサービス) のFlutterモバイルアプリケーションです。アプリは会話を地図上に浮かぶ吹き出しとして表示し、「土地の記憶」と呼ばれるAIシステムが場所の履歴に基づいて文脈的な応答を提供します。

## 必須ドキュメント参照

**変更を行う前に、必ず`/doc/`にあるこれらのドキュメントファイルを参照してください：**

- `/doc/requirements.md` - 7つの主要機能の完全なユーザーストーリーと受け入れ基準
- `/doc/design.md` - 技術アーキテクチャ、API仕様、詳細な実装ガイダンス
- `/doc/task.md` - StadiaMapsを使用した地図機能の段階的実装ガイド

これらのドキュメントには完全な仕様が含まれており、実装に関する決定を行う際は必ず参照してください。

## 一般的な開発コマンド

### 依存関係とセットアップ
```bash
# 依存関係のインストール
flutter pub get

# クリーンして依存関係を再インストール
flutter clean && flutter pub get
```

### 開発とテスト
```bash
# 環境ファイルで実行（.env方式 - 推奨）
flutter run

# 明示的なAPIキーで実行（dart-define方式）
flutter run --dart-define=STADIA_API_KEY=あなたのAPIキー

# プラットフォーム固有の実行
flutter run -d ios
flutter run -d android
flutter run -d ios --dart-define=STADIA_API_KEY=あなたのAPIキー
flutter run -d android --dart-define=STADIA_API_KEY=あなたのAPIキー

# 解析とリント
flutter analyze
```

### 環境設定
プロジェクトでは地図タイルに**StadiaMaps**を使用します。APIキーは以下で設定してください：
- `frontend/.env`ファイル（推奨アプローチ）
- または`--dart-define=STADIA_API_KEY=key`コマンドライン引数

## アーキテクチャ概要

### 現在の実装状況
- **プロジェクト構造**: カスタムドキュメント付きの標準Flutterプロジェクト
- **地図実装**: 計画済みだが未実装（現在はデフォルトのFlutterデモを表示）
- **コア依存関係**: `flutter_map: ^5.0.0`, `latlong2: ^0.9.0`, `url_launcher: ^6.1.6`, `flutter_dotenv: ^5.1.0`

### 計画されたアーキテクチャ（design.mdより）
```
フロントエンド: Flutter/Dart クロスプラットフォームアプリ
地図サービス: flutter_mapを使ったStadiaMaps
状態管理: Riverpod（計画）
バックエンド: Supabase（計画）
位置情報サービス: 権限処理付きGeolocator
地理的インデックス: Geohashベースの空間組織化
```

### 目標ディレクトリ構造
```
lib/
├── main.dart                      # エントリーポイント
├── app/
│   └── app.dart                   # アプリケーションルート
├── core/
│   ├── constants/                 # アプリケーション定数
│   ├── errors/                    # エラー定義
│   └── utils/                     # ユーティリティ
└── features/
    ├── map/
    │   ├── presentation/          # 地図UI画面
    │   ├── widgets/               # 地図コンポーネント
    │   └── services/              # 地図関連サービス
    ├── post/
    │   ├── models/                # データモデル
    │   ├── services/              # API連携
    │   └── widgets/               # 投稿UIコンポーネント
    └── auth/
        └── services/              # 匿名ID管理
```

## 主要機能（requirements.mdより）

1. **インタラクティブ地図表示** - 3秒のロード時間、現在地または横浜駅をデフォルト
2. **会話の吹き出し** - 場所ベースの投稿を浮かぶ吹き出しとして表示
3. **AI土地の記憶** - 「土地の記憶」システムからの文脈的応答
4. **友達システム** - 15分以内の共同位置に基づく一時的な関係
5. **マルチレベルズーム** - ズームに基づく異なる会話詳細レベル（geohash精度5-7）
6. **オフラインサポート** - 接続不良時のキャッシュされた会話
7. **プライバシー重視** - 日次ローテーションの匿名ハンドル、最小限の個人データ

## 主要技術詳細

### 環境変数
- **STADIA_API_KEY**: 地図タイルアクセスに必要
- **地図スタイル**: StadiaMapsの`alidade_smooth_dark`テーマ
- **デフォルト位置**: 位置情報許可が拒否された場合の横浜駅（35.4658, 139.6201）

### パフォーマンス要件
- **地図ロード時間**: ≤3秒
- **フレームレート**: パン/ズーム操作中に60fps
- **吹き出し制限**: 画面あたり最大30個の吹き出し
- **API応答**: 土地の記憶の応答は0.5-2.0秒

### プライバシーとセキュリティ
- **匿名ハンドル**: 日次ローテーションのユーザー識別子
- **個人データなし**: 匿名ハンドルのみ保存
- **Geohashベース位置**: 位置匿名化のための空間インデックス
- **環境保護**: .envファイルによるAPIキー、gitから除外

## 開発ワークフロー

1. **実装前**: `/doc/requirements.md`と`/doc/design.md`の関連セクションを読む
2. **API統合**: StadiaMapsセットアップは`/doc/task.md`のパターンに従う
3. **状態管理**: design.mdで指定されたRiverpodを使用
4. **テスト**: ビジネスロジック（BubbleManager、FriendshipManager、ApiService）に焦点
5. **エラーハンドリング**: ネットワーク呼び出しのリトライロジック、位置情報の横浜駅フォールバックを実装

## 重要な注意事項

- **現在の状態**: アプリはFlutterデモを表示；実際の地図実装は構築が必要
- **ドキュメント優先**: アーキテクチャ決定前に必ず`/doc/`ファイルを参照
- **地図サービス**: StadiaMapsが選択されたプロバイダー（Google Mapsなどではない）
- **AI統合**: 「土地の記憶」システムは0.5-2.0秒の応答遅延が必要
- **Geohash精度**: ズームレベルに基づいて精度5-7を使用（requirements.mdで詳細）