import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../location/services/location_service.dart';
import '../../location/services/live_location_controller.dart';
import '../../../core/constants/location_config.dart';
import '../widgets/dev_tools/dev_joystick.dart';
import '../widgets/dev_tools/dev_location_service.dart';


// 水彩画風　stamen_watercolor
// const _styleUrl ="https://tiles.stadiamaps.com/tiles/stamen_watercolor/{z}/{x}/{y}.jpg";

// スタイリング無し版
const _styleUrl =
    "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final LocationService _locationService = LocationService();
  final LiveLocationController _liveLocationController = LiveLocationController();
  LatLng? _currentLocation;
  String _locationStatus = '位置情報未取得';
  double? _lastZoomLevel;
  
  // 開発ツール関連
  LatLng _virtualLocation = LocationConfig.defaultLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    LocationConfig.log(LocationConfig.mapScreenTag, '🗺️ MapScreen初期化開始');
    
    // 開発ツール初期化
    _initializeDevTools();
    
    _checkInitialLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    // ズームレベルが1単位以上変化したときのみログ出力
    if (_lastZoomLevel == null || (position.zoom - _lastZoomLevel!).abs() >= 1.0) {
      LocationConfig.log(LocationConfig.mapScreenTag, 'ズームレベル変更: ${_lastZoomLevel?.toStringAsFixed(1) ?? "初期"} → ${position.zoom.toStringAsFixed(1)}');
      _lastZoomLevel = position.zoom;
    }
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

    LocationConfig.log(LocationConfig.mapScreenTag, '📊 初期状態: $_locationStatus');
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
        LocationConfig.log(LocationConfig.mapScreenTag, '📍 現在位置: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}');
        
        setState(() {
          _currentLocation = location;
          _locationStatus = '位置情報追跡中';
        });
        
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
      LocationConfig.log(LocationConfig.mapScreenTag, '🎯 仮想位置に移動: lat=${_virtualLocation.latitude.toStringAsFixed(6)}, lng=${_virtualLocation.longitude.toStringAsFixed(6)}');
    } else {
      targetLocation = _currentLocation;
      if (targetLocation != null) {
        LocationConfig.log(LocationConfig.mapScreenTag, '📍 現在地に移動: lat=${targetLocation.latitude.toStringAsFixed(6)}, lng=${targetLocation.longitude.toStringAsFixed(6)}');
      }
    }
    
    if (targetLocation != null) {
      // 現在地に移動してズームレベルを適切に設定
      _mapController.move(targetLocation, LocationConfig.compassZoom);
      
      // 地図の回転を北向き（0度）にリセット
      _mapController.rotate(0);
      
      LocationConfig.log(LocationConfig.mapScreenTag, '🧭 地図を現在地に移動し、北向きに調整しました');
    } else {
      LocationConfig.log(LocationConfig.mapScreenTag, '⚠️ 現在地が取得されていません');
      // 現在地が不明な場合はデフォルト位置（横浜駅）に移動
      _mapController.move(LocationConfig.defaultLocation, LocationConfig.defaultZoom);
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
      LocationConfig.log(LocationConfig.mapScreenTag, '🎯 現在位置を仮想位置で初期化: lat=${_virtualLocation.latitude.toStringAsFixed(6)}, lng=${_virtualLocation.longitude.toStringAsFixed(6)}');
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
    
    // ジョイスティック操作時は地図中心を現在地に追従
    _mapController.move(newLocation, _mapController.camera.zoom);
    
    LocationConfig.log(
      LocationConfig.mapScreenTag, 
      '🎮 ジョイスティック: 仮想位置更新・地図中心移動 lat=${newLocation.latitude.toStringAsFixed(6)}, lng=${newLocation.longitude.toStringAsFixed(6)}'
    );
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
                  markers: [
                    Marker(
                      point: _shouldShowDevTools ? _virtualLocation : _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _shouldShowDevTools 
                            ? Colors.orange.withValues(alpha: 0.8) 
                            : Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _shouldShowDevTools ? Icons.developer_mode : Icons.person_pin_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              // アトリビューション（レイヤーとして配置）
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('StadiaMaps'),
                  // TextSourceAttribution(
                  //   "Stamen Design",
                  //   onTap: () => launchUrl(Uri.parse("https://stamen.com/")),
                  //   prependCopyright: true,
                  // ),
                  TextSourceAttribution(
                    "OpenStreetMap",
                    onTap: () =>
                        launchUrl(Uri.parse("https://www.openstreetmap.org/copyright")),
                    prependCopyright: true,
                  ),
                ],
              ),
            ],
          ),

          // ステータス表示（上部）
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _locationStatus,
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
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
                  'DEV MODE\n現在位置: ${_virtualLocation.latitude.toStringAsFixed(4)}, ${_virtualLocation.longitude.toStringAsFixed(4)}\n🕹️ ジョイスティックで移動（地図追従）\n🧭 コンパスで現在位置に移動',
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

      // コンパスボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        tooltip: '現在地に移動して北向きに調整',
        child: FaIcon(
          FontAwesomeIcons.compass,
          size: 24,
        ),
      ),
    );
  }
}
