import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'location_api_service.dart';
import '../../auth/services/auth_service.dart';
import '../../post/services/post_service.dart';
import '../../post/models/post.dart';

class CellTrackingService {
  final LocationApiService _locationApiService = LocationApiService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  Cell? _currentCell;
  StreamController<List<Post>>? _postsController;

  Stream<List<Post>>? get postsStream => _postsController?.stream;

  Future<void> initialize() async {
    await _authService.loadStoredTokens();
    
    if (!_authService.isAuthenticated) {
      final signupSuccess = await _authService.signup();
      if (!signupSuccess) {
        throw Exception('認証に失敗しました');
      }
    }

    _postsController = StreamController<List<Post>>.broadcast();
  }

  Future<void> onLocationChanged(LatLng location) async {
    try {
      final locationData = await _locationApiService.getCurrentLocation(
        location.latitude,
        location.longitude,
      );

      if (locationData == null) {
        return;
      }

      if (_currentCell == null || _currentCell != locationData.cell) {
        print('Cell changed: ${_currentCell?.geoHash} -> ${locationData.cell.geoHash}');
        _currentCell = locationData.cell;
        
        await _fetchAndBroadcastPosts(location.latitude, location.longitude);
      }
    } catch (e) {
      print('Cell tracking error: $e');
    }
  }

  Future<void> _fetchAndBroadcastPosts(double lat, double lon) async {
    try {
      final posts = await _postService.getPostsByLocation(lat, lon);
      
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _postsController?.add(posts);
      print('投稿を取得しました: ${posts.length}件');
    } catch (e) {
      print('投稿取得エラー: $e');
      _postsController?.add([]);
    }
  }

  void dispose() {
    _postsController?.close();
    _postsController = null;
  }
}