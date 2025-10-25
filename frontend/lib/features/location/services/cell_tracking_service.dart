import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'location_api_service.dart';
import '../../auth/services/auth_service.dart';
import '../../post/services/post_service.dart';
import '../../post/models/post.dart';
import '../../post/models/create_post_response.dart';
import '../../../core/constants/location_config.dart';

class CellTrackingService {
  final LocationApiService _locationApiService = LocationApiService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  Cell? _currentCell;
  StreamController<List<Post>>? _postsController;
  List<Post> _displayedPosts = []; // 画面に表示されている投稿
  List<Post> _pendingPosts = []; // 表示待ちキュー
  Timer? _displayTimer;

  Stream<List<Post>>? get postsStream => _postsController?.stream;

  static const Duration displayInterval = Duration(milliseconds: 500); // 表示間隔

  Future<void> initialize() async {
    await _authService.loadStoredTokens();

    if (!_authService.isAuthenticated) {
      final signupSuccess = await _authService.signup();
      if (!signupSuccess) {
        throw Exception('認証に失敗しました');
      }
    }

    _postsController = StreamController<List<Post>>.broadcast();
    _startDisplayTimer();
  }

  /// 表示タイマーを開始
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(displayInterval, (_) {
      _displayNextPost();
    });

    LocationConfig.log(
      'CellTrackingService',
      '⏱️ 表示タイマー開始: ${displayInterval.inSeconds}秒間隔',
    );
  }

  /// 表示待ちキューから次の投稿を1件取り出して表示
  void _displayNextPost() {
    if (_pendingPosts.isEmpty) {
      return;
    }

    // キューの先頭を取り出して表示リストに追加
    final post = _pendingPosts.removeAt(0);
    _displayedPosts.add(post);

    LocationConfig.log(
      'CellTrackingService',
      '✨ 投稿を表示: "${post.text}" (残り待ち: ${_pendingPosts.length}件)',
    );

    // 画面に反映
    _postsController?.add([..._displayedPosts]);
  }

  Future<void> onLocationChanged(LatLng location) async {
    LocationConfig.log(
      'CellTrackingService',
      '📍 位置変更: lat=${location.latitude.toStringAsFixed(6)}, lon=${location.longitude.toStringAsFixed(6)}',
    );

    try {
      final locationData = await _locationApiService.getCurrentLocation(
        location.latitude,
        location.longitude,
      );

      if (locationData == null) {
        LocationConfig.log(
          'CellTrackingService',
          '⚠️ getCurrentLocationがnullを返しました',
        );
        return;
      }

      LocationConfig.log(
        'CellTrackingService',
        '📱 セル情報取得: ${locationData.cell.geoHash} (ID: ${locationData.cell.id})',
      );

      final isCellChanged = _currentCell == null || _currentCell != locationData.cell;
      final needsMorePosts = _displayedPosts.length < 10;

      if (isCellChanged) {
        LocationConfig.log(
          'CellTrackingService',
          '🔄 セル変更検出: ${_currentCell?.geoHash ?? "初期化"} → ${locationData.cell.geoHash}',
        );
        _currentCell = locationData.cell;
        await _fetchAndBroadcastPosts(location.latitude, location.longitude);
      } else if (needsMorePosts) {
        LocationConfig.log(
          'CellTrackingService',
          '📥 同じセル内だが投稿数不足(${_displayedPosts.length}件) → 投稿を再取得',
        );
        await _fetchAndBroadcastPosts(location.latitude, location.longitude);
      } else {
        LocationConfig.log(
          'CellTrackingService',
          '✅ 同じセル内で投稿充足(${_displayedPosts.length}件) → 投稿取得をスキップ',
        );
      }
    } catch (e) {
      LocationConfig.log(
        'CellTrackingService',
        '❌ onLocationChangedエラー: $e',
      );
      // エラー時は現在の表示状態を保持
      _postsController?.add([..._displayedPosts]);
    }
  }

  Future<void> _fetchAndBroadcastPosts(double lat, double lon) async {
    LocationConfig.log(
      'CellTrackingService',
      '🔍 投稿取得開始: lat=${lat.toStringAsFixed(6)}, lon=${lon.toStringAsFixed(6)}',
    );

    try {
      final newPosts = await _postService.getPostsByLocation(lat, lon);

      LocationConfig.log(
        'CellTrackingService',
        '✅ 投稿取得成功: ${newPosts.length}件',
      );

      // 新しい投稿を表示待ちキューに追加（重複チェック付き）
      _addPostsToQueue(newPosts);
    } catch (e) {
      LocationConfig.log(
        'CellTrackingService',
        '❌ 投稿取得エラー: $e',
      );
    }
  }

  /// 投稿を表示待ちキューに追加（重複チェック付き）
  void _addPostsToQueue(List<Post> newPosts) {
    // 既に表示済み、または表示待ちの投稿IDを収集
    final existingIds = {
      ..._displayedPosts.map((p) => p.id),
      ..._pendingPosts.map((p) => p.id),
    };

    // 重複していない投稿のみをキューに追加
    final uniquePosts = newPosts.where((p) => !existingIds.contains(p.id)).toList();

    if (uniquePosts.isEmpty) {
      return;
    }

    _pendingPosts.addAll(uniquePosts);

    LocationConfig.log(
      'CellTrackingService',
      '📥 キューに追加: ${uniquePosts.length}件 (現在の待ち: ${_pendingPosts.length}件)',
    );
  }

  /// 楽観的UI更新で投稿を作成
  Future<void> createPostOptimistically({
    required double lat,
    required double lng,
    required String text,
  }) async {
    LocationConfig.log(
      'CellTrackingService',
      '✏️ 投稿作成開始: "$text"',
    );

    // 1. 一時的な投稿を作成
    final optimisticPost = Post(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      lat: lat,
      lng: lng,
      kind: PostKind.user,
      text: text,
      createdAt: DateTime.now(),
      userId: _authService.userId,
    );

    // 楽観的投稿をキューに追加（すぐに表示される）
    _pendingPosts.add(optimisticPost);

    LocationConfig.log(
      'CellTrackingService',
      '⚡ 楽観的投稿をキューに追加 (待ち: ${_pendingPosts.length}件)',
    );

    try {
      // 2. バックグラウンドでAPI実行
      final response = await _postService.createPost(
        lat: lat,
        lng: lng,
        text: text,
      );

      LocationConfig.log(
        'CellTrackingService',
        '📬 投稿作成API成功: 類似投稿${response.similarPosts.length}件',
      );

      // 3. 楽観的投稿を削除（表示済みリストと待ちキューの両方から）
      _displayedPosts.removeWhere((p) => p.id == optimisticPost.id);
      _pendingPosts.removeWhere((p) => p.id == optimisticPost.id);

      // レスポンスから投稿を優先度順に取得
      final responsePosts = _flattenResponsePosts(response);

      LocationConfig.log(
        'CellTrackingService',
        '📝 レスポンスから取得した投稿: ${responsePosts.length}件',
      );

      // 優先度順にソートしてキューに追加
      _addPostsToQueue(responsePosts);

      LocationConfig.log(
        'CellTrackingService',
        '✅ 投稿作成完了: 待ちキュー${_pendingPosts.length}件',
      );
    } catch (e) {
      LocationConfig.log(
        'CellTrackingService',
        '❌ 投稿作成API失敗: $e',
      );
      // API失敗時は楽観的投稿を削除
      _displayedPosts.removeWhere((p) => p.id == optimisticPost.id);
      _pendingPosts.removeWhere((p) => p.id == optimisticPost.id);
      _postsController?.add([..._displayedPosts]);
      rethrow;
    }
  }

  /// レスポンスから投稿を優先度順に展開
  /// 優先度: 1.作成投稿 2.その返信(古い順) 3.類似投稿(古い順) 4.類似投稿の返信(古い順)
  List<Post> _flattenResponsePosts(CreatePostResponse response) {
    final postsWithPriority = <_PostWithPriority>[];

    // 1. 作成された投稿（優先度0、最優先）
    postsWithPriority.add(_PostWithPriority(
      post: response.post,
      priority: 0,
      sortKey: response.post.createdAt,
    ));

    // 2. 作成された投稿への返信（優先度1、古い順）
    for (final reply in response.post.replies) {
      postsWithPriority.add(_PostWithPriority(
        post: reply.copyWith(kind: PostKind.land),
        priority: 1,
        sortKey: reply.createdAt,
      ));
    }

    // 3. 類似投稿（優先度2、古い順）
    for (final similarPost in response.similarPosts) {
      postsWithPriority.add(_PostWithPriority(
        post: similarPost,
        priority: 2,
        sortKey: similarPost.createdAt,
      ));

      // 4. 類似投稿への返信（優先度3、古い順）
      for (final reply in similarPost.replies) {
        postsWithPriority.add(_PostWithPriority(
          post: reply.copyWith(kind: PostKind.land),
          priority: 3,
          sortKey: reply.createdAt,
        ));
      }
    }

    // 優先度順、同一優先度内では古い順にソート
    postsWithPriority.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.sortKey.compareTo(b.sortKey);
    });

    final sortedPosts = postsWithPriority.map((p) => p.post).toList();

    LocationConfig.log(
      'CellTrackingService',
      '📋 投稿展開: 本体1件 + 返信${response.post.replies.length}件 + 類似${response.similarPosts.length}件 = ${sortedPosts.length}件（優先度順）',
    );

    return sortedPosts;
  }

  void dispose() {
    _displayTimer?.cancel();
    _displayTimer = null;
    _postsController?.close();
    _postsController = null;
  }
}

/// 投稿と優先度を保持する内部クラス
class _PostWithPriority {
  final Post post;
  final int priority;
  final DateTime sortKey;

  _PostWithPriority({
    required this.post,
    required this.priority,
    required this.sortKey,
  });
}