# Codama API Documentation

## 概要

Codamaは地図ベースのSNS APIです。ユーザーは位置情報付きの投稿を作成し、特定の場所周辺の投稿を取得できます。

## ベースURL

```
http://localhost:8000
```

## 認証

現在のバージョンでは認証は不要です（最低限の実装）。

## エンドポイント

### 1. Health Check

サーバーの稼働状態を確認します。

```http
GET /
```

**レスポンス例**
```json
{
  "status": "ok",
  "message": "Codama API is running"
}
```

---

### 2. ポスト作成

新しいポストを作成します。

```http
POST /posts
```

**リクエストボディ**
```json
{
  "username": "john_doe",
  "text": "Hello from Tokyo!",
  "latitude": 35.6812,
  "longitude": 139.7671
}
```

**フィールド説明**
- `username` (string, required): 投稿者のユーザー名（1-50文字）
- `text` (string, required): 投稿内容（1-500文字）
- `latitude` (float, required): 緯度（-90 ~ 90）
- `longitude` (float, required): 経度（-180 ~ 180）

**レスポンス: 201 Created**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "username": "john_doe",
  "text": "Hello from Tokyo!",
  "latitude": 35.6812,
  "longitude": 139.7671,
  "created_at": "2025-10-25T12:00:00Z"
}
```

---

### 3. 周辺ポスト取得

指定した位置から一定範囲内のポストを取得します。

```http
GET /posts/nearby?latitude=35.6812&longitude=139.7671&radius=1.0
```

**クエリパラメータ**
- `latitude` (float, required): 検索中心点の緯度（-90 ~ 90）
- `longitude` (float, required): 検索中心点の経度（-180 ~ 180）
- `radius` (float, optional): 検索半径（km単位、デフォルト: 1.0、最大: 100.0）

**レスポンス: 200 OK**
```json
{
  "posts": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "username": "john_doe",
      "text": "Hello from Tokyo!",
      "latitude": 35.6812,
      "longitude": 139.7671,
      "created_at": "2025-10-25T12:00:00Z"
    }
  ]
}
```

---

## 開発環境のセットアップ

### 依存関係のインストール

```bash
cd backend
uv sync
```

### サーバーの起動

```bash
python main.py
```

または

```bash
uvicorn main:app --reload
```

### APIドキュメントの確認

サーバー起動後、以下のURLでインタラクティブなAPIドキュメントにアクセスできます：

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## データモデル

### Post

| フィールド | 型 | 説明 |
|----------|-----|------|
| id | UUID | ポストの一意識別子（自動生成） |
| username | string | 投稿者のユーザー名 |
| text | string | 投稿内容 |
| latitude | float | 緯度 |
| longitude | float | 経度 |
| created_at | datetime | 投稿日時（自動生成） |

## TODO

以下の機能は今後実装予定です：

- [ ] Supabaseとの連携（データベース実装）
- [ ] 位置情報による検索機能の実装
- [ ] ユーザー認証
- [ ] 画像アップロード機能
- [ ] いいね・コメント機能
- [ ] ポストの編集・削除

## エラーレスポンス

APIはHTTPステータスコードを使用してエラーを示します：

- `400 Bad Request`: リクエストパラメータが不正
- `404 Not Found`: リソースが見つからない
- `500 Internal Server Error`: サーバー内部エラー
- `501 Not Implemented`: 機能が未実装

**エラーレスポンス例**
```json
{
  "detail": "エラーメッセージ"
}
```
