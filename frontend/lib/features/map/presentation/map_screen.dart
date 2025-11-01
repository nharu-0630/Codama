import 'package:codama/core/constants/config.dart';
import 'package:codama/core/di/providers.dart';
import 'package:codama/core/providers/auth_provider.dart';
import 'package:codama/features/auth/widgets/signup_modal.dart';
import 'package:codama/features/location/services/live_location_controller.dart';
import 'package:codama/features/location/services/location_service.dart';
import 'package:codama/features/map/widgets/bubble_position.dart';
import 'package:codama/features/map/widgets/dev_tools/dev_joystick.dart';
import 'package:codama/features/map/widgets/dev_tools/dev_location_service.dart';
import 'package:codama/features/post/services/bubble_manager.dart';
import 'package:codama/features/post/widgets/bubble_widget.dart';
import 'package:codama/features/post/widgets/create_post_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:latlong2/latlong.dart';
import 'package:openapi/openapi.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late MapController _mapController;
  final LocationService _locationService = LocationService();
  final LiveLocationController _liveLocationController =
      LiveLocationController();
  LatLng? _currentLocation;
  double? _lastZoomLevel;
  bool _isInitialized = false;

  LatLng _virtualLocation = Config.defaultLocation;

  final BubbleManager _bubbleManager = BubbleManager();
  List<BubblePosition> _bubblePositions = [];

  static const double _circleRadiusMeters = 150.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeDevTools();
    _startLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationAndInitialize();
    });
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    if (_lastZoomLevel == null ||
        (position.zoom - _lastZoomLevel!).abs() >= 1.0) {
      _lastZoomLevel = position.zoom;
    }
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    if (!mounted) return;

    try {
      final apiService = await ref.read(apiServiceProvider.future);
      final isAuthenticated = apiService.isAuthenticated();
      if (!isAuthenticated) {
        _showSignupModal();
        return;
      }
      await _initializeCellTracking();
    } catch (e) {
      if (mounted) {
        _showSignupModal();
      }
    }
  }

  Future<void> _initializeCellTracking() async {
    if (!mounted) return;

    try {
      final cellTrackingService = await ref.read(
        cellTrackingServiceProvider.future,
      );
      await cellTrackingService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Cell tracking initialization failed, but we continue without it
    }
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
      try {
        final cellTrackingService = await ref.read(
          cellTrackingServiceProvider.future,
        );
        cellTrackingService.createPost(loc: loc, text: text);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  bool _isInsideCircle(LatLng position) {
    final loc = _shouldShowDevTools ? _virtualLocation : _currentLocation;
    if (loc == null) return true;
    const distance = Distance();
    final distanceMeters = distance.as(LengthUnit.Meter, loc, position);
    return distanceMeters <= _circleRadiusMeters;
  }

  void _showPostDetail(APIPostOutput post) {
    final isLandMemory = post.userUuid == null;

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
              isLandMemory ? 'とちの声' : 'ひとの声',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isLandMemory
                    ? Colors.purple.shade700
                    : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLandMemory
                    ? Colors.purple.shade800
                    : Colors.blue.shade800,
              ),
            ),
            Text(
              '聞こえたとき: ${post.createdAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall,
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
      onLocationUpdate: (LatLng location) async {
        _currentLocation = location;
        try {
          final cellTrackingService = await ref.read(
            cellTrackingServiceProvider.future,
          );
          cellTrackingService.onLocationChanged(location);
        } catch (e) {
          // Handle error silently
        }
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
      _mapController.move(targetLocation, Config.compassZoom);
      _mapController.rotate(0);
    } else {
      _mapController.move(Config.defaultLocation, Config.defaultZoom);
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
    ref
        .read(cellTrackingServiceProvider.future)
        .then((cellTrackingService) {
          cellTrackingService.onLocationChanged(newLocation);
        })
        .catchError((e) {
          // Handle error silently
        });
    _mapController.move(newLocation, _mapController.camera.zoom);
  }

  bool get _shouldShowDevTools {
    return kDebugMode && DevLocationService.isDevToolsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (previous == true && next == false) {
        _showSignupModal();
      }
    });

    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cellTrackingServiceAsync = ref.watch(cellTrackingServiceProvider);
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';

    return cellTrackingServiceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          const Scaffold(body: Center(child: Text('Error loading services'))),
      data: (cellTrackingService) => StreamBuilder<List<APIPostOutput>>(
        stream: cellTrackingService.postsStream,
        builder: (context, postsSnapshot) {
          final posts = postsSnapshot.data ?? [];

          return StreamBuilder<String?>(
            stream: cellTrackingService.areaNameStream,
            builder: (context, areaSnapshot) {
              final areaName = areaSnapshot.data ?? '読み込み中...';

              // Update bubble positions when posts change
              if (posts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateBubblePositionsWithPosts(posts);
                });
              }

              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(areaName),
                  titleTextStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                body: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentLocation ?? Config.defaultLocation,
                        initialZoom: Config.defaultZoom,
                        maxZoom: Config.maxZoom,
                        minZoom: Config.minZoom,
                        onPositionChanged: _onPositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "${Config.styleUrl}?api_key={api_key}",
                          additionalOptions: {"api_key": apiKey},
                          maxZoom: 20,
                        ),
                        if (_currentLocation != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _shouldShowDevTools
                                    ? _virtualLocation
                                    : _currentLocation!,
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
                                    border: IconBorder(
                                      color: Colors.white,
                                      width: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (_bubblePositions.isNotEmpty)
                          MarkerLayer(
                            rotate: true,
                            markers: _bubblePositions.reversed.map((
                              bubblePosition,
                            ) {
                              final isInside = _isInsideCircle(
                                bubblePosition.position,
                              );
                              return Marker(
                                point: bubblePosition.position,
                                width: 200,
                                height: 80,
                                alignment: Alignment.bottomCenter,
                                child: BubbleWidget(
                                  post: bubblePosition.post,
                                  displayKind: bubblePosition.displayKind,
                                  onTap: () =>
                                      _showPostDetail(bubblePosition.post),
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
                      child: const Icon(Icons.edit),
                    ),
                  ],
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
              );
            },
          );
        },
      ),
    );
  }

  void _updateBubblePositionsWithPosts(List<APIPostOutput> posts) {
    final currentLoc = _shouldShowDevTools
        ? _virtualLocation
        : _currentLocation;
    if (currentLoc == null) {
      return;
    }

    // Create view bounds based on current location and radius
    const distance = Distance();
    final radiusKm = _circleRadiusMeters / 1000;

    final northEast = distance.offset(currentLoc, radiusKm, 45);
    final southWest = distance.offset(currentLoc, radiusKm, 225);

    final viewBounds = ViewBounds(
      north: northEast.latitude,
      south: southWest.latitude,
      east: northEast.longitude,
      west: southWest.longitude,
    );

    ref
        .read(apiServiceProvider.future)
        .then((apiService) {
          final currentUserId = apiService.getCurrentUserId();

          final newPositions = _bubbleManager.layoutBubbles(
            posts,
            viewBounds,
            currentUserId,
          );

          setState(() {
            _bubblePositions = newPositions;
          });
        })
        .catchError((e) {});
  }
}
