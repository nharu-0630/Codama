import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'location_api_service.dart';
import '../../auth/services/auth_service.dart';
import '../../post/services/post_service.dart';
import '../../post/models/post.dart';
import '../../post/models/create_post_response.dart';

class CellTrackingService {
  final LocationApiService _locationApiService = LocationApiService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  Cell? _currentCell;
  StreamController<List<Post>>? _postsController;
  List<Post> _currentPosts = [];

  Stream<List<Post>>? get postsStream => _postsController?.stream;

  Future<void> initialize() async {
    await _authService.loadStoredTokens();
    
    print('認証状態チェック - isAuthenticated: ${_authService.isAuthenticated}');
    print('認証状態チェック - accessToken: ${_authService.accessToken?.substring(0, 20)}...');
    
    if (!_authService.isAuthenticated) {
      print('認証が必要です、signup実行中...');
      final signupSuccess = await _authService.signup();
      if (!signupSuccess) {
        throw Exception('認証に失敗しました');
      }
      print('signup完了 - isAuthenticated: ${_authService.isAuthenticated}');
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
      final newPosts = await _postService.getPostsByLocation(lat, lon);

      // 既存の投稿に新しい投稿を追加（重複排除）
      final allPosts = [..._currentPosts];
      for (final newPost in newPosts) {
        // 同じIDの投稿が既に存在しない場合のみ追加
        if (!allPosts.any((p) => p.id == newPost.id)) {
          allPosts.add(newPost);
        }
      }

      // created_atでソート（古い順）
      allPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 30件の上限を適用（古い投稿から削除）
      final limitedPosts = allPosts.length > 30
          ? allPosts.sublist(allPosts.length - 30)
          : allPosts;

      _currentPosts = limitedPosts;
      _postsController?.add(limitedPosts);
      print('投稿を更新しました: 新規${newPosts.length}件取得、表示中${limitedPosts.length}件');
    } catch (e) {
      print('投稿取得エラー: $e');
      // エラー時は既存の投稿を保持
      _postsController?.add(_currentPosts);
    }
  }

  /// 楽観的UI更新で投稿を作成
  /// 1. 一時的な投稿を即座に画面に表示
  /// 2. バックグラウンドでAPI実行
  /// 3. APIレスポンス（回答・類似投稿）で画面を更新
  Future<void> createPostOptimistically({
    required double lat,
    required double lng,
    required String text,
  }) async {
    // 1. 一時的な投稿をすぐに画面に表示
    final optimisticPost = Post(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      lat: lat,
      lng: lng,
      kind: PostKind.user,
      text: text,
      createdAt: DateTime.now(),
      userId: _authService.userId,
    );

    // 即座に投稿リストに追加して表示
    final updatedPosts = [..._currentPosts, optimisticPost];
    _currentPosts = updatedPosts;
    _postsController?.add(updatedPosts);
    print('楽観的投稿を追加: $text');

    try {
      // 2. バックグラウンドでAPI実行
      final response = await _postService.createPost(
        lat: lat,
        lng: lng,
        text: text,
      );

      print('=== CreatePostResponse受信 ===');
      print('response.post.id: ${response.post.id}');
      print('response.post.text: ${response.post.text}');
      print('response.post.replies (${response.post.replies.length}件):');
      for (var i = 0; i < response.post.replies.length; i++) {
        print('  [$i] id=${response.post.replies[i].id}, text=${response.post.replies[i].text}');
      }
      print('response.similarPosts (${response.similarPosts.length}件):');
      for (var i = 0; i < response.similarPosts.length; i++) {
        print('  [$i] id=${response.similarPosts[i].id}, text=${response.similarPosts[i].text}, replies=${response.similarPosts[i].replies.length}件');
      }
      print('==============================');

      // 3. API結果で投稿を置き換え & LLM返信・類似投稿を追加
      final newPosts = _currentPosts.where((p) => p.id != optimisticPost.id).toList();

      // 作成された投稿を追加
      newPosts.add(response.post);

      // 土地の記憶からの返信がある場合、それらをlandとして追加
      for (final reply in response.post.replies) {
        // 既にPostオブジェクトなので、kindをlandに変更して追加
        final landPost = reply.copyWith(kind: PostKind.land);
        newPosts.add(landPost);
      }
      
      // 類似投稿とその土地の記憶の返信を追加
      for (final similarPost in response.similarPosts) {
        if (!newPosts.any((p) => p.id == similarPost.id)) {
          newPosts.add(similarPost);

          // 類似投稿に対する土地の記憶の返信も追加
          for (final reply in similarPost.replies) {
            if (!newPosts.any((p) => p.id == reply.id)) {
              final landPost = reply.copyWith(kind: PostKind.land);
              newPosts.add(landPost);
            }
          }
        }
      }

      // created_at でソート
      newPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 30件の上限を適用（古い投稿から削除）
      final limitedPosts = newPosts.length > 30
          ? newPosts.sublist(newPosts.length - 30)
          : newPosts;

      _currentPosts = limitedPosts;
      _postsController?.add(limitedPosts);
      print('API応答で投稿を更新: 新投稿+返信${response.post.replies.length}件+類似投稿${response.similarPosts.length}件 → 表示${limitedPosts.length}件');
      
    } catch (e) {
      // API失敗時は楽観的投稿を削除
      final fallbackPosts = _currentPosts.where((p) => p.id != optimisticPost.id).toList();
      _currentPosts = fallbackPosts;
      _postsController?.add(fallbackPosts);
      print('投稿API失敗、楽観的投稿を削除: $e');
      rethrow;
    }
  }

  void dispose() {
    _postsController?.close();
    _postsController = null;
  }
}