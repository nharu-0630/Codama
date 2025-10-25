# 地図実装

## 概要
StadiaMapsとflutter_mapを使用した地図機能の実装

## 実装手順

### 1. パッケージの追加
**ファイル**: `frontend/pubspec.yaml`

以下の依存関係を追加:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^5.0.0
  latlong2: ^0.9.0
  url_launcher: ^6.1.6
  flutter_dotenv: ^5.1.0
```

**依存関係の取得**:
```bash
cd frontend
flutter pub get
```

### 2. ディレクトリ構造
以下のファイルを作成:

```
lib/
   main.dart                      # エントリーポイント
   app/
      app.dart                   # アプリケーション
   features/
       map/
           presentation/
              map_screen.dart    # 地図画面
           widgets/
               map_attribution.dart # 地図のクレジット表示
```

### 3. 環境変数の設定

#### 方法1: .envファイルを使用（推奨）

**1. .envファイルの作成**
`frontend/.env`:
```
STADIA_API_KEY=あなたのAPIキー
```

**2. .gitignoreに追加**
`frontend/.gitignore`:
```
.env
```

**3. pubspec.yamlに.envを含める**
`frontend/pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

### 4. メインファイルの実装
**ファイル**: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const KodamaMapApp());
}
```

### 5. アプリケーションの実装
**ファイル**: `lib/app/app.dart`

```dart
import 'package:flutter/material.dart';
import '../features/map/presentation/map_screen.dart';

class KodamaMapApp extends StatelessWidget {
  const KodamaMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kodama Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
```

### 6. 地図画面の実装
**ファイル**: `lib/features/map/presentation/map_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/map_attribution.dart';

const _styleUrl = "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';
    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          center: LatLng(35.4658, 139.6201), // 横浜駅
          zoom: 15,
          keepAlive: true,
          maxZoom: 18,
          minZoom: 10,
        ),
        nonRotatedChildren: const [MapAttribution()],
        children: [
          TileLayer(
            urlTemplate: "$_styleUrl?api_key={api_key}",
            additionalOptions: {"api_key": apiKey},
            maxZoom: 20,
            maxNativeZoom: 20,
          ),
        ],
      ),
    );
  }
}
```

### 7. 地図のクレジット表示の実装
**ファイル**: `lib/features/map/widgets/map_attribution.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(attributions: [
      TextSourceAttribution(
        "Stadia Maps",
        onTap: () => launchUrl(Uri.parse("https://stadiamaps.com/")),
        prependCopyright: true,
      ),
      TextSourceAttribution(
        "OpenMapTiles",
        onTap: () => launchUrl(Uri.parse("https://openmaptiles.org/")),
        prependCopyright: true,
      ),
      TextSourceAttribution(
        "OpenStreetMap",
        onTap: () => launchUrl(
          Uri.parse("https://www.openstreetmap.org/copyright"),
        ),
        prependCopyright: true,
      ),
    ]);
  }
}
```

### 8. StadiaMaps APIキーの取得
1. [StadiaMaps](https://stadiamaps.com/)でアカウントを作成
2. ダッシュボードでAPIキーを作成
3. APIキーを環境変数として設定

### 9. アプリケーションの起動

**開発環境での起動**:

#### .envファイルを使用している場合:
```bash
# 通常の起動
flutter run

# iOS シミュレータで起動
flutter run -d ios

# Androidで起動
flutter run -d android
```

#### dart-defineを使用する場合:
```bash
# APIキーを環境変数として指定して起動
flutter run --dart-define=STADIA_API_KEY=あなたのAPIキー

# iOS シミュレータで起動
flutter run -d ios --dart-define=STADIA_API_KEY=あなたのAPIキー

# Androidで起動
flutter run -d android --dart-define=STADIA_API_KEY=あなたのAPIキー
```

### 10. 追加機能の実装
- [ ] 地図スタイルの切り替え
- [ ] 現在位置の表示
- [ ] マーカー/ピンの追加
- [ ] ルート検索機能の追加
- [ ] オフラインマップのサポート
- [ ] ユーザー位置情報の権限管理

### 11. トラブルシューティング

#### 地図が表示されない場合
1. APIキーが正しく設定されているか確認
2. インターネット接続を確認
3. `flutter clean && flutter pub get`を実行

#### ビルドエラーの場合
1. Flutter SDKのバージョンが3.0以上であることを確認
2. パッケージのバージョンを確認
3. iOS/Androidの最小サポートバージョンを確認

## 次の実装
地図表示の後に実装する機能:
1. 現在位置の取得と表示
2. マーカー機能の実装
3. 検索機能との統合
4. ルート案内機能

## 参考
- [StadiaMaps Flutter Map Documentation](https://docs.stadiamaps.com/native-multiplatform/flutter-map/)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [設計書](design.md)