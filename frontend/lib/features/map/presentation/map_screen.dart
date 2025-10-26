import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/location_config.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/signup_modal.dart';
import '../../location/services/cell_tracking_service.dart';
import '../../location/services/live_location_controller.dart';
import '../../location/services/location_service.dart';
import '../../post/models/bubble_position.dart';
import '../../post/models/post.dart';
import '../../post/services/bubble_manager.dart';
import '../../post/widgets/bubble_widget.dart';
import '../../post/widgets/create_post_dialog.dart';
import '../widgets/dev_tools/dev_joystick.dart';
import '../widgets/dev_tools/dev_location_service.dart';

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
  String? _currentAreaName;
  double? _lastZoomLevel;

  LatLng _virtualLocation = LocationConfig.defaultLocation;

  final BubbleManager _bubbleManager = BubbleManager();
  List<Post> _posts = [];
  List<BubblePosition> _bubblePositions = [];

  // 150m radius circle
  static const double _circleRadiusMeters = 150.0;
  LatLng? _mapCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeDevTools();

    _startLocationTracking();
    _checkAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    _cellTrackingService.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    if (_lastZoomLevel == null ||
        (position.zoom - _lastZoomLevel!).abs() >= 1.0) {
      _lastZoomLevel = position.zoom;
    }
    setState(() {
      _mapCenter = position.center;
    });
    _updateBubblePositions();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    try {
      await _authService.loadStoredTokens();
      if (!_authService.isAuthenticated) {
        _showSignupModal();
        return;
      }
      await _initializeCellTracking();
    } catch (e) {
      _showSignupModal();
    }
  }

  Future<void> _initializeCellTracking() async {
    try {
      await _cellTrackingService.initialize();
      _cellTrackingService.postsStream?.listen((posts) {
        setState(() {
          _posts = posts;
        });
        _updateBubblePositions();
      });
      _cellTrackingService.areaNameStream?.listen((areaName) {
        setState(() {
          _currentAreaName = areaName;
        });
      });
    } catch (e) {}
  }

  void _showSignupModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignupModal(
        onSuccess: () async {
          await _initializeCellTracking();
        },
      ),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        onPostCreate: (String text) async {
          _createPost(text);
        },
      ),
    );
  }

  Future<void> _createPost(String text) async {
    final loc = _shouldShowDevTools ? _virtualLocation : _currentLocation;
    if (loc != null) {
      _cellTrackingService.createPost(loc: loc, text: text);
    }
  }

  bool _isInsideCircle(LatLng position) {
    if (_mapCenter == null) return true;
    const distance = Distance();
    final distanceMeters = distance.as(LengthUnit.Meter, _mapCenter!, position);
    return distanceMeters <= _circleRadiusMeters;
  }

  void _updateBubblePositions() {
    if (_posts.isEmpty) {
      return;
    }
    try {
      final camera = _mapController.camera;
      final bounds = ViewBounds(
        north: camera.visibleBounds.north,
        south: camera.visibleBounds.south,
        east: camera.visibleBounds.east,
        west: camera.visibleBounds.west,
      );
      final bubblePositions = _bubbleManager.layoutBubbles(
        _posts,
        bounds,
        _authService.userId,
      );
      setState(() {
        _bubblePositions = bubblePositions;
      });
    } catch (e) {
      // エラーが発生した場合はバブル位置の更新をスキップ
      print('Error updating bubble positions: $e');
    }
  }

  void _showPostDetail(Post post) {
    final isLandMemory = post.kind == PostKind.land;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (isLandMemory) ...[
              Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              isLandMemory ? '土地の記憶' : 'ユーザー投稿',
              style: TextStyle(
                color: isLandMemory
                    ? Colors.purple.shade700
                    : Colors.blue.shade700,
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

  Future<void> _startLocationTracking() async {
    await _liveLocationController.startTracking(
      onLocationUpdate: (LatLng location) {
        setState(() {
          _currentLocation = location;
        });
        _cellTrackingService.onLocationChanged(location);
      },
      onError: (Object error) {},
    );
  }

  void _centerOnCurrentLocation() {
    LatLng? targetLocation;
    if (_shouldShowDevTools) {
      targetLocation = _virtualLocation;
    } else {
      targetLocation = _currentLocation;
    }
    if (targetLocation != null) {
      _mapController.move(targetLocation, LocationConfig.compassZoom);
      _mapController.rotate(0);
    } else {
      _mapController.move(
        LocationConfig.defaultLocation,
        LocationConfig.defaultZoom,
      );
      _mapController.rotate(0);
    }
  }

  void _initializeDevTools() {
    if (DevLocationService.isDevToolsEnabled) {
      _locationService.setVirtualLocation(_virtualLocation);
      setState(() {
        _currentLocation = _virtualLocation;
      });
    }
  }

  void _onVirtualLocationChange(LatLng newLocation) {
    setState(() {
      _virtualLocation = newLocation;
      _currentLocation = newLocation;
    });
    _locationService.setVirtualLocation(newLocation);
    _cellTrackingService.onLocationChanged(newLocation);
    _mapController.move(newLocation, _mapController.camera.zoom);
  }

  bool get _shouldShowDevTools {
    return kDebugMode && DevLocationService.isDevToolsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_currentAreaName ?? '読み込み中...'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: [
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
              if (_mapCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _mapCenter!,
                      radius: _circleRadiusMeters,
                      useRadiusInMeter: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderColor: Colors.orange,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_currentLocation != null)
                MarkerLayer(
                  rotate: true,
                  markers: [
                    Marker(
                      point: _shouldShowDevTools
                          ? _virtualLocation
                          : _currentLocation!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: DecoratedIcon(
                        icon: Icon(
                          Icons.navigation,
                          color: Colors.orange,
                          size: 40,
                        ),
                        decoration: IconDecoration(
                          border: IconBorder(color: Colors.white, width: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_bubblePositions.isNotEmpty)
                MarkerLayer(
                  rotate: true,
                  markers: _bubblePositions.reversed.map((bubblePosition) {
                    final isInside = _isInsideCircle(bubblePosition.position);
                    return Marker(
                      point: bubblePosition.position,
                      width: 200,
                      height: bubblePosition.height,
                      alignment: Alignment.bottomCenter,
                      child: BubbleWidget(
                        post: bubblePosition.post,
                        displayKind: bubblePosition.displayKind,
                        onTap: () => _showPostDetail(bubblePosition.post),
                        showContent: isInside,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DevJoystick(
                currentLocation: _virtualLocation,
                onLocationChange: _onVirtualLocationChange,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 16,
        children: [
          FloatingActionButton(
            heroTag: "compass",
            onPressed: _centerOnCurrentLocation,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            child: const Icon(Icons.my_location),
          ),
          FloatingActionButton(
            heroTag: "create_post",
            onPressed: _showCreatePostDialog,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
