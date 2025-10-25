import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../location/services/location_service.dart';
import '../../location/services/live_location_controller.dart';

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
  final LiveLocationController _liveLocationController =
      LiveLocationController();
  LatLng? _currentLocation;
  String _locationStatus = '位置情報未取得';
  double? _lastZoomLevel;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    debugPrint('[MapScreen] 🗺️ MapScreen初期化開始');
    _checkInitialLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    // ズームレベルが変化したときだけログ出力
    if (_lastZoomLevel != position.zoom) {
      debugPrint('[MapScreen] ズームレベル変更: ${_lastZoomLevel?.toStringAsFixed(1) ?? "初期"} → ${position.zoom.toStringAsFixed(1)}');
      _lastZoomLevel = position.zoom;
    }
  }

  /// 初期位置情報チェック
  Future<void> _checkInitialLocation() async {
    debugPrint('[MapScreen] 🔍 初期位置情報チェック開始');

    final hasPermission = await _locationService.checkPermissionStatus();
    final serviceEnabled = await _locationService.isLocationServiceEnabled();

    setState(() {
      _locationStatus =
          '権限: ${_getPermissionText(hasPermission)}, '
          'サービス: ${serviceEnabled ? "有効" : "無効"}';
    });

    debugPrint('[MapScreen] 📊 初期状態: $_locationStatus');
  }

  /// 画面開始時に自動で位置情報追跡を開始
  Future<void> _startLocationTracking() async {
    debugPrint('[MapScreen] 🚀 自動で常時追跡を開始します');
    
    setState(() {
      _locationStatus = '位置情報追跡開始中...';
    });

    await _liveLocationController.startTracking(
      onLocationUpdate: (LatLng location) {
        // 現在座標を常にログに出力
        debugPrint('[MapScreen] 📍 現在位置: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}');
        
        setState(() {
          _currentLocation = location;
          _locationStatus = '位置情報追跡中';
        });
        
        // 地図の中心を現在地に自動移動（ズームレベルは維持）
        _mapController.move(location, _mapController.camera.zoom);
      },
      onError: (Object error) {
        debugPrint('[MapScreen] ❌ 自動追跡エラー: $error');
        setState(() {
          _locationStatus = '追跡エラー: $error';
        });
      },
    );
  }


  /// コンパスボタンが押されたときの処理（現在地に移動 + 北向き）
  void _centerOnCurrentLocation() {
    debugPrint('[MapScreen] 🧭 コンパスボタンが押されました');
    
    if (_currentLocation != null) {
      // 現在地に移動してズームレベルを適切に設定
      _mapController.move(_currentLocation!, 16);
      
      // 地図の回転を北向き（0度）にリセット
      _mapController.rotate(0);
      
      debugPrint('[MapScreen] 🧭 地図を現在地に移動し、北向きに調整しました');
    } else {
      debugPrint('[MapScreen] ⚠️ 現在地が取得されていません');
      // 現在地が不明な場合はデフォルト位置（横浜駅）に移動
      _mapController.move(LatLng(35.4658, 139.6201), 15);
      _mapController.rotate(0);
    }
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
              initialCenter:
                  _currentLocation ?? LatLng(35.4658, 139.6201), // 横浜駅
              initialZoom: 15,
              maxZoom: 18,
              minZoom: 10,
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
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              // アトリビューション（レイヤーとして配置）
              RichAttributionWidget(
                attributions: [TextSourceAttribution('StadiaMaps')],
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
