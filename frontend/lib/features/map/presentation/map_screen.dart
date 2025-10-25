import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../location/services/location_service.dart';
import '../../location/services/live_location_controller.dart';
import '../../location/services/cell_tracking_service.dart';
import '../../../core/constants/location_config.dart';
import '../widgets/dev_tools/dev_joystick.dart';
import '../widgets/dev_tools/dev_location_service.dart';
import '../../post/models/post.dart';
import '../../post/models/bubble_position.dart';
import '../../post/services/bubble_manager.dart';
import '../../post/widgets/bubble_widget.dart';
import '../../post/widgets/create_post_dialog.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/signup_modal.dart';

// 水彩画風　stamen_watercolor
const _styleUrl =
    "https://tiles.stadiamaps.com/tiles/stamen_watercolor/{z}/{x}/{y}.jpg";

// スタイリング無し版
// const _styleUrl =
//     "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final LocationService _locationService = LocationService();
  final LiveLocationController _liveLocationController =
      LiveLocationController();
  final CellTrackingService _cellTrackingService = CellTrackingService();
  final AuthService _authService = AuthService();
  LatLng? _currentLocation;
  String _locationStatus = '位置情報未取得';
  double? _lastZoomLevel;

  // 開発ツール関連
  LatLng _virtualLocation = LocationConfig.defaultLocation;

  // 吹き出し関連
  final BubbleManager _bubbleManager = BubbleManager();
  List<Post> _posts = [];
  List<BubblePosition> _bubblePositions = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    LocationConfig.log(LocationConfig.mapScreenTag, '🗺️ MapScreen初期化開始');

    // 開発ツール初期化
    _initializeDevTools();

    _checkInitialLocation();
    _startLocationTracking();

    // 認証チェックとサービス初期化
    _checkAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    _cellTrackingService.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    // ズームレベルが1単位以上変化したときのみログ出力
    if (_lastZoomLevel == null ||
        (position.zoom - _lastZoomLevel!).abs() >= 1.0) {
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        'ズームレベル変更: ${_lastZoomLevel?.toStringAsFixed(1) ?? "初期"} → ${position.zoom.toStringAsFixed(1)}',
      );
      _lastZoomLevel = position.zoom;
    }

    // 地図移動時に吹き出し位置を更新
    _updateBubblePositions();
  }

  /// 認証チェックとサービス初期化
  Future<void> _checkAuthenticationAndInitialize() async {
    try {
      // 保存されたトークンを読み込み
      await _authService.loadStoredTokens();

      // 認証されていない場合はサインアップモーダルを表示
      if (!_authService.isAuthenticated) {
        LocationConfig.log(LocationConfig.mapScreenTag, '🔒 認証が必要です、サインアップモーダルを表示');
        _showSignupModal();
        return;
      }

      // 認証済みの場合はサービスを初期化
      await _initializeCellTracking();

    } catch (e) {
      LocationConfig.log(LocationConfig.mapScreenTag, '❌ 認証チェックエラー: $e');
      _showSignupModal();
    }
  }

  /// セル追跡サービスを初期化
  Future<void> _initializeCellTracking() async {
    try {
      await _cellTrackingService.initialize();

      // 投稿ストリームを監視
      _cellTrackingService.postsStream?.listen((posts) {
        setState(() {
          _posts = posts;
        });
        _updateBubblePositions();
        LocationConfig.log(
          LocationConfig.mapScreenTag,
          '📱 セル変更により投稿を更新しました: ${posts.length}件',
        );
      });
    } catch (e) {
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '❌ セル追跡サービス初期化エラー: $e',
      );
    }
  }

  /// サインアップモーダルを表示
  void _showSignupModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignupModal(
        onSuccess: () async {
          LocationConfig.log(LocationConfig.mapScreenTag, '✅ サインアップ成功、サービスを初期化');
          await _initializeCellTracking();
        },
      ),
    );
  }


  /// 特定座標に投稿を作成（楽観的UI更新）
  Future<void> createPostAtLocation({
    required double lat,
    required double lng,
    required String text,
  }) async {
    try {
      // 認証が必要な処理として実行（自動リフレッシュ付き）
      await _authService.withAuth(() async {
        await _cellTrackingService.createPostOptimistically(
          lat: lat,
          lng: lng,
          text: text,
        );
      });

      LocationConfig.log(LocationConfig.mapScreenTag, '✅ 投稿作成成功: $text');
    } on AuthenticationRequiredException catch (e) {
      LocationConfig.log(LocationConfig.mapScreenTag, '🔒 認証エラー、サインアップモーダルを表示: $e');
      _showSignupModal();
    } catch (e) {
      LocationConfig.log(LocationConfig.mapScreenTag, '❌ 投稿作成エラー: $e');
      
      // 認証関連のエラーの場合はサインアップモーダルを表示
      if (e.toString().contains('認証') || e.toString().contains('authorization')) {
        _showSignupModal();
      } else {
        // その他のエラーは再スロー
        rethrow;
      }
    }
  }

  /// 投稿作成ダイアログを表示
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        onPostCreate: (String text) async {
          await _createPostAtCurrentLocation(text);
        },
      ),
    );
  }

  /// 現在地に投稿を作成
  Future<void> _createPostAtCurrentLocation(String text) async {
    // 現在地または開発ツールの仮想位置を使用
    final location = _shouldShowDevTools ? _virtualLocation : _currentLocation;

    if (location == null) {
      // 位置情報が取得できない場合はデフォルト位置（横浜駅）を使用
      await createPostAtLocation(
        lat: LocationConfig.defaultLocation.latitude,
        lng: LocationConfig.defaultLocation.longitude,
        text: text,
      );
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '⚠️ 位置情報未取得のためデフォルト位置に投稿',
      );
    } else {
      await createPostAtLocation(
        lat: location.latitude,
        lng: location.longitude,
        text: text,
      );
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '💬 投稿作成: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
      );
    }
  }

  /// 吹き出し位置を更新
  void _updateBubblePositions() {
    if (_posts.isEmpty) {
      LocationConfig.log(LocationConfig.mapScreenTag, '⚠️ 投稿が空です');
      return;
    }

    // MapControllerが準備できているか確認
    try {
      final camera = _mapController.camera;
      final bounds = ViewBounds(
        north: camera.visibleBounds.north,
        south: camera.visibleBounds.south,
        east: camera.visibleBounds.east,
        west: camera.visibleBounds.west,
      );

      // LocationConfig.log(LocationConfig.mapScreenTag, '📍 画面範囲: N${bounds.north.toStringAsFixed(4)}, S${bounds.south.toStringAsFixed(4)}, E${bounds.east.toStringAsFixed(4)}, W${bounds.west.toStringAsFixed(4)}');

      final bubblePositions = _bubbleManager.layoutBubbles(
        _posts,
        bounds,
        'current_user', // TODO: 実際のユーザーIDを使用
      );

      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '💬 表示する吹き出し: ${bubblePositions.length}件',
      );

      setState(() {
        _bubblePositions = bubblePositions;
      });
    } catch (e) {
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '⚠️ MapController未準備: $e',
      );
    }
  }

  /// 吹き出しタップ時の処理
  void _onBubbleTap(Post post) {
    _showPostDetail(post);
  }

  /// 投稿詳細を表示
  void _showPostDetail(Post post) {
    final isLandMemory = post.kind == PostKind.land;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (isLandMemory) ...[
              Icon(
                Icons.auto_awesome,
                color: Colors.purple.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isLandMemory ? '土地の記憶' : 'ユーザー投稿',
              style: TextStyle(
                color: isLandMemory ? Colors.purple.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.text,
              style: TextStyle(
                fontStyle: isLandMemory ? FontStyle.italic : FontStyle.normal,
                color: isLandMemory ? Colors.purple.shade600 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isLandMemory ? "出現" : "投稿"}時刻: ${post.createdAt.toString().substring(0, 19)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 初期位置情報チェック
  Future<void> _checkInitialLocation() async {
    LocationConfig.log(LocationConfig.mapScreenTag, '🔍 初期位置情報チェック開始');

    final hasPermission = await _locationService.checkPermissionStatus();
    final serviceEnabled = await _locationService.isLocationServiceEnabled();

    setState(() {
      _locationStatus =
          '権限: ${_getPermissionText(hasPermission)}, '
          'サービス: ${serviceEnabled ? "有効" : "無効"}';
    });

    LocationConfig.log(
      LocationConfig.mapScreenTag,
      '📊 初期状態: $_locationStatus',
    );
  }

  /// 画面開始時に自動で位置情報追跡を開始
  Future<void> _startLocationTracking() async {
    LocationConfig.log(LocationConfig.mapScreenTag, '🚀 自動で常時追跡を開始します');

    setState(() {
      _locationStatus = '位置情報追跡開始中...';
    });

    await _liveLocationController.startTracking(
      onLocationUpdate: (LatLng location) {
        // 現在座標を常にログに出力
        // LocationConfig.log(
        //   LocationConfig.mapScreenTag,
        //   '📍 現在位置: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
        // );

        setState(() {
          _currentLocation = location;
          _locationStatus = '位置情報追跡中';
        });

        // セル追跡サービスに位置変更を通知
        _cellTrackingService.onLocationChanged(location);

        // 地図の中心は自動移動しない（ユーザーが自由に地図を操作できるように）
        // コンパスボタンで現在地に戻ることができる
      },
      onError: (Object error) {
        LocationConfig.log(LocationConfig.mapScreenTag, '❌ 自動追跡エラー: $error');
        setState(() {
          _locationStatus = '追跡エラー: $error';
        });
      },
    );
  }

  /// コンパスボタンが押されたときの処理（現在地に移動 + 北向き）
  void _centerOnCurrentLocation() {
    LocationConfig.log(LocationConfig.mapScreenTag, '🧭 コンパスボタンが押されました');

    // 開発ツールが有効な場合は仮想位置を使用、そうでなければ実際の現在地を使用
    LatLng? targetLocation;
    if (_shouldShowDevTools) {
      targetLocation = _virtualLocation;
      // LocationConfig.log(
      //   LocationConfig.mapScreenTag,
      //   '🎯 仮想位置に移動: lat=${_virtualLocation.latitude.toStringAsFixed(6)}, lng=${_virtualLocation.longitude.toStringAsFixed(6)}',
      // );
    } else {
      targetLocation = _currentLocation;
      if (targetLocation != null) {
        // LocationConfig.log(
        //   LocationConfig.mapScreenTag,
        //   '📍 現在地に移動: lat=${targetLocation.latitude.toStringAsFixed(6)}, lng=${targetLocation.longitude.toStringAsFixed(6)}',
        // );
      }
    }

    if (targetLocation != null) {
      // 現在地に移動してズームレベルを適切に設定
      _mapController.move(targetLocation, LocationConfig.compassZoom);

      // 地図の回転を北向き（0度）にリセット
      _mapController.rotate(0);

      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '🧭 地図を現在地に移動し、北向きに調整しました',
      );
    } else {
      LocationConfig.log(LocationConfig.mapScreenTag, '⚠️ 現在地が取得されていません');
      // 現在地が不明な場合はデフォルト位置（横浜駅）に移動
      _mapController.move(
        LocationConfig.defaultLocation,
        LocationConfig.defaultZoom,
      );
      _mapController.rotate(0);
    }
  }

  /// 開発ツール初期化
  void _initializeDevTools() {
    if (DevLocationService.isDevToolsEnabled) {
      LocationConfig.log(LocationConfig.mapScreenTag, '🛠️ 開発ツールを初期化しています');

      // デフォルト仮想位置を設定
      _locationService.setVirtualLocation(_virtualLocation);

      // 仮想位置を現在位置として設定
      setState(() {
        _currentLocation = _virtualLocation;
      });

      _locationService.logDevToolsState();
      LocationConfig.log(
        LocationConfig.mapScreenTag,
        '🎯 現在位置を仮想位置で初期化: lat=${_virtualLocation.latitude.toStringAsFixed(6)}, lng=${_virtualLocation.longitude.toStringAsFixed(6)}',
      );
    }
  }

  /// ジョイスティックによる仮想位置変更処理
  void _onVirtualLocationChange(LatLng newLocation) {
    setState(() {
      _virtualLocation = newLocation;
      // 仮想位置を現在位置として設定
      _currentLocation = newLocation;
    });

    // LocationServiceに仮想位置を設定
    _locationService.setVirtualLocation(newLocation);

    // セル追跡サービスに位置変更を通知
    _cellTrackingService.onLocationChanged(newLocation);

    // ジョイスティック操作時は地図中心を現在地に追従
    _mapController.move(newLocation, _mapController.camera.zoom);

    // LocationConfig.log(
    //   LocationConfig.mapScreenTag,
    //   '🎮 ジョイスティック: 仮想位置更新・地図中心移動 lat=${newLocation.latitude.toStringAsFixed(6)}, lng=${newLocation.longitude.toStringAsFixed(6)}',
    // );
  }

  /// 開発ツールが表示されるべきかチェック
  bool get _shouldShowDevTools {
    return kDebugMode && DevLocationService.isDevToolsEnabled;
  }

  String _getPermissionText(permission) {
    switch (permission.toString()) {
      case 'LocationPermission.denied':
        return '拒否';
      case 'LocationPermission.deniedForever':
        return '永続拒否';
      case 'LocationPermission.whileInUse':
        return '使用中のみ';
      case 'LocationPermission.always':
        return '常に許可';
      default:
        return '不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // 地図表示
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LocationConfig.defaultLocation,
              initialZoom: LocationConfig.defaultZoom,
              maxZoom: LocationConfig.maxZoom,
              minZoom: LocationConfig.minZoom,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: "$_styleUrl?api_key={api_key}",
                additionalOptions: {"api_key": apiKey},
                maxZoom: 20,
              ),
              // 現在地マーカー（取得済みの場合）
              if (_currentLocation != null)
                MarkerLayer(
                  rotate: true, // 地図回転時にマーカーを逆回転させて画面向きを保つ
                  markers: [
                    Marker(
                      point: _shouldShowDevTools
                          ? _virtualLocation
                          : _currentLocation!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center, // 中央を基準点に
                      child: Container(
                        decoration: BoxDecoration(
                          color: _shouldShowDevTools
                              ? Colors.orange.withValues(alpha: 0.8)
                              : Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _shouldShowDevTools
                              ? Icons.developer_mode
                              : Icons.person_pin_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              // 吹き出し表示（逆順にして後から表示した吹き出しを手前に）
              if (_bubblePositions.isNotEmpty)
                MarkerLayer(
                  rotate: true, // 地図回転時にマーカーを逆回転させて画面向きを保つ
                  markers: _bubblePositions.reversed.map((bubblePosition) {
                    return Marker(
                      point: bubblePosition.position,
                      width: 200,
                      height: bubblePosition.height,
                      alignment: Alignment.bottomCenter, // 吹き出しの下端中央を基準点に
                      child: BubbleWidget(
                        post: bubblePosition.post,
                        onTap: () => _onBubbleTap(bubblePosition.post),
                      ),
                    );
                  }).toList(),
                ),
              // アトリビューション（レイヤーとして配置）
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('StadiaMaps'),
                  TextSourceAttribution(
                    "Stamen Design",
                    onTap: () => launchUrl(Uri.parse("https://stamen.com/")),
                    prependCopyright: true,
                  ),
                  // TextSourceAttribution(
                  //   "OpenStreetMap",
                  //   onTap: () => launchUrl(
                  //     Uri.parse("https://www.openstreetmap.org/copyright"),
                  //   ),
                  //   prependCopyright: true,
                  // ),
                ],
              ),
            ],
          ),

          // 開発ツール: ジョイスティック（左下）
          if (_shouldShowDevTools)
            Positioned(
              bottom: 16,
              left: 16,
              child: DevJoystick(
                currentLocation: _virtualLocation,
                onLocationChange: _onVirtualLocationChange,
              ),
            ),

          // 開発ツール状態表示（右下）
          if (_shouldShowDevTools)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '現在位置: ${_virtualLocation.latitude.toStringAsFixed(4)}, ${_virtualLocation.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),

      // フローティングアクションボタン（プラスボタン）
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // コンパスボタン
          FloatingActionButton(
            heroTag: "compass",
            onPressed: _centerOnCurrentLocation,
            tooltip: '現在地に移動して北向きに調整',
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            child: FaIcon(FontAwesomeIcons.compass, size: 24),
          ),

          const SizedBox(height: 16),

          // 投稿作成ボタン
          FloatingActionButton(
            heroTag: "create_post",
            onPressed: _showCreatePostDialog,
            tooltip: '新しい投稿を作成',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
