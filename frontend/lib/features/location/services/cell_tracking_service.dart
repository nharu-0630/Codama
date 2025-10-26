import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../../../core/constants/location_config.dart';
import '../../auth/services/auth_service.dart';
import '../../post/models/create_post_response.dart';
import '../../post/models/post.dart';
import '../../post/services/post_service.dart';
import 'location_api_service.dart';

/// 一時投稿（5秒で消える投稿）を保持するクラス
class TemporaryPost {
  final Post post;
  final DateTime displayStartTime;

  TemporaryPost({required this.post, required this.displayStartTime});
}

class CellTrackingService {
  final LocationApiService _locationApiService = LocationApiService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  Cell? _currentCell;
  StreamController<List<Post>>? _postsController;
  List<Post> _displayedPosts = []; // 画面に表示されている投稿
  List<Post> _pendingPosts = []; // 表示待ちキュー
  List<TemporaryPost> _temporaryPosts = []; // 一時投稿（5秒で消える）
  Timer? _displayTimer;
  Timer? _cleanupTimer;

  Stream<List<Post>>? get postsStream => _postsController?.stream;

  static const Duration displayInterval = Duration(milliseconds: 500); // 表示間隔
  static const Duration temporaryPostLifetime = Duration(
    seconds: 5,
  ); // 一時投稿の有効期限
  static const Duration cleanupInterval = Duration(seconds: 1); // クリーンアップ間隔

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
    _startCleanupTimer();
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(displayInterval, (_) {
      _displayNextPost();
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _cleanupExpiredTemporaryPosts();
    });
  }

  void _cleanupExpiredTemporaryPosts() {
    final now = DateTime.now();
    final beforeCount = _temporaryPosts.length;
    _temporaryPosts.removeWhere((tempPost) {
      final elapsed = now.difference(tempPost.displayStartTime);
      return elapsed >= temporaryPostLifetime;
    });
    final removedCount = beforeCount - _temporaryPosts.length;
    if (removedCount > 0) {
      _broadcastAllPosts();
    }
  }

  void _displayNextPost() {
    if (_pendingPosts.isEmpty) {
      return;
    }
    final post = _pendingPosts.removeAt(0);
    _displayedPosts.add(post);
    _broadcastAllPosts();
  }

  void _broadcastAllPosts() {
    final allPosts = [
      ..._displayedPosts,
      ..._temporaryPosts.map((temp) => temp.post),
    ];
    _postsController?.add(allPosts);
  }

  Future<void> onLocationChanged(LatLng loc) async {
    try {
      final current = await _locationApiService.getCurrentLocation(
        loc.latitude,
        loc.longitude,
      );
      if (current == null) {
        return;
      }

      if (_currentCell == null || _currentCell != current.cell) {
        _currentCell = current.cell;
        final posts = await _postService.getPostsByLocation(
          loc.latitude,
          loc.longitude,
        );
        _addPostsToQueue(posts);
      }
    } catch (e) {}
  }

  void _addPostsToQueue(List<Post> newPosts) {
    final existingIds = {
      ..._displayedPosts.map((p) => p.id),
      ..._pendingPosts.map((p) => p.id),
    };
    final uniquePosts = newPosts
        .where((p) => !existingIds.contains(p.id))
        .toList();
    if (uniquePosts.isEmpty) {
      return;
    }
    _pendingPosts.addAll(uniquePosts);
  }

  void _addTemporaryPosts(List<Post> newPosts) {
    final existingIds = _temporaryPosts.map((temp) => temp.post.id).toSet();
    final now = DateTime.now();
    for (final post in newPosts) {
      if (!existingIds.contains(post.id)) {
        _temporaryPosts.add(TemporaryPost(post: post, displayStartTime: now));
      }
    }
  }

  Future<void> createPost({required LatLng loc, required String text}) async {
    final optimisticPost = Post(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      lat: loc.latitude,
      lng: loc.longitude,
      kind: PostKind.user,
      text: text,
      createdAt: DateTime.now(),
      userId: _authService.userId,
      isTemporary: false,
    );
    _pendingPosts.add(optimisticPost);
    try {
      final response = await _postService.createPost(
        lat: loc.latitude,
        lng: loc.longitude,
        text: text,
      );
      _displayedPosts.removeWhere((p) => p.id == optimisticPost.id);
      _pendingPosts.removeWhere((p) => p.id == optimisticPost.id);

      final responsePosts = _flattenResponsePosts(response);
      _addTemporaryPosts(responsePosts);
      _addPostsToQueue([response.post]);
    } catch (e) {
      _displayedPosts.removeWhere((p) => p.id == optimisticPost.id);
      _pendingPosts.removeWhere((p) => p.id == optimisticPost.id);
    } finally {
      _broadcastAllPosts();
    }
  }

  /// レスポンスから投稿を優先度順に展開
  /// 優先度: 1.作成投稿 2.その返信(古い順) 3.類似投稿(古い順) 4.類似投稿の返信(古い順)
  List<Post> _flattenResponsePosts(CreatePostResponse response) {
    final postsWithPriority = <_PostWithPriority>[];

    // 1. 作成された投稿（優先度0、最優先）
    // 自分の投稿なので、userIdが含まれていない場合は設定する
    // 一時投稿として5秒で消えるようにする
    final createdPost = response.post.copyWith(
      userId: response.post.userId ?? _authService.userId,
      isTemporary: true,
    );

    // 2. 作成された投稿への返信（優先度1、古い順）
    for (final reply in createdPost.replies) {
      postsWithPriority.add(
        _PostWithPriority(
          post: reply.copyWith(kind: PostKind.land, isTemporary: true),
          priority: 1,
          sortKey: reply.createdAt,
        ),
      );
    }

    // 3. 類似投稿（優先度2、古い順）
    for (final similarPost in response.similarPosts) {
      postsWithPriority.add(
        _PostWithPriority(
          post: similarPost.copyWith(isTemporary: true),
          priority: 2,
          sortKey: similarPost.createdAt,
        ),
      );

      // 4. 類似投稿への返信（優先度3、古い順）
      for (final reply in similarPost.replies) {
        postsWithPriority.add(
          _PostWithPriority(
            post: reply.copyWith(kind: PostKind.land, isTemporary: true),
            priority: 3,
            sortKey: reply.createdAt,
          ),
        );
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
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _postsController?.close();
    _postsController = null;
  }
}

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
