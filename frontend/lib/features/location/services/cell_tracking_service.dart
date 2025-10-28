import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../../auth/services/auth_service.dart';
import '../../post/models/create_post_response.dart';
import '../../post/models/post.dart';
import '../../post/services/post_service.dart';
import 'location_api_service.dart';
import 'post_display_manager.dart';
import 'temporary_post_manager.dart';

class CellTrackingService {
  final LocationApiService _locationApiService = LocationApiService();
  final AuthService _authService = AuthService();
  final PostService _postService;
  final PostDisplayManager _displayManager = PostDisplayManager();
  final TemporaryPostManager _temporaryManager = TemporaryPostManager();

  CellTrackingService({required AuthService authService})
    : _postService = PostService(authService: authService);

  Cell? _currentCell;
  String? _currentAreaName;
  StreamController<List<Post>>? _postsController;
  StreamController<String?>? _areaNameController;

  Stream<List<Post>>? get postsStream => _postsController?.stream;
  Stream<String?>? get areaNameStream => _areaNameController?.stream;
  String? get currentAreaName => _currentAreaName;

  // 投稿表示の優先度定数
  static const int _priorityCreatedPostReplies = 1; // 作成投稿の返信（最優先）
  static const int _prioritySimilarPosts = 2; // 類似投稿
  static const int _prioritySimilarPostReplies = 3; // 類似投稿の返信

  Future<void> initialize() async {
    await _authService.loadStoredTokens();
    if (!_authService.isAuthenticated) {
      final signupSuccess = await _authService.signup();
      if (!signupSuccess) {
        throw Exception('認証に失敗しました');
      }
    }

    _postsController = StreamController<List<Post>>.broadcast();
    _areaNameController = StreamController<String?>.broadcast();
    _displayManager.start(_broadcastAllPosts);
    _temporaryManager.start(_broadcastAllPosts);
  }

  void _broadcastAllPosts() {
    final allPosts = [
      ..._displayManager.getDisplayedPosts(),
      ..._temporaryManager.getTemporaryPosts(),
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

      // エリア名が変わったら通知
      if (_currentAreaName != current.area.name) {
        _currentAreaName = current.area.name;
        _areaNameController?.add(_currentAreaName);
      }

      if (_currentCell == null || _currentCell != current.cell) {
        _currentCell = current.cell;
        final posts = await _postService.getPostsByLocation(
          loc.latitude,
          loc.longitude,
        );
        _addPostsToQueue(posts);
      }
    } catch (e) {
      // 位置情報の取得に失敗した場合は何もしない
    }
  }

  void _addPostsToQueue(List<Post> newPosts) {
    _displayManager.addPostsToQueue(newPosts);
  }

  void _addTemporaryPosts(List<Post> newPosts) {
    _temporaryManager.addTemporaryPosts(newPosts, _broadcastAllPosts);
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
    _displayManager.addPostsToQueue([optimisticPost]);
    try {
      final response = await _postService.createPost(
        lat: loc.latitude,
        lng: loc.longitude,
        text: text,
      );
      final responsePosts = _flattenResponsePosts(response);
      _addTemporaryPosts(responsePosts);
      _addPostsToQueue([response.post]);
    } catch (e) {
      // 投稿作成に失敗した場合は何もしない
    } finally {
      _displayManager.removePostById(optimisticPost.id);
      _broadcastAllPosts();
    }
  }

  /// レスポンスから投稿を優先度順に展開
  /// 優先度: 1.作成投稿の返信 2.類似投稿 3.類似投稿の返信（各優先度内では古い順）
  List<Post> _flattenResponsePosts(CreatePostResponse response) {
    final postsWithPriority = <_PostWithPriority>[];

    // 作成された投稿（一時投稿として5秒で消える）
    final createdPost = _makeTemporaryPost(
      response.post,
      userId: _authService.userId,
    );

    // 1. 作成された投稿への返信を追加
    _addRepliesToList(
      postsWithPriority,
      createdPost.replies,
      _priorityCreatedPostReplies,
    );

    // 2. 類似投稿とその返信を追加
    for (final similarPost in response.similarPosts) {
      postsWithPriority.add(
        _PostWithPriority(
          post: _makeTemporaryPost(similarPost),
          priority: _prioritySimilarPosts,
          sortKey: similarPost.createdAt,
        ),
      );

      _addRepliesToList(
        postsWithPriority,
        similarPost.replies,
        _prioritySimilarPostReplies,
      );
    }

    return _sortByPriority(postsWithPriority);
  }

  Post _makeTemporaryPost(Post post, {String? userId}) {
    return post.copyWith(userId: userId ?? post.userId, isTemporary: true);
  }

  void _addRepliesToList(
    List<_PostWithPriority> list,
    List<Post> replies,
    int priority,
  ) {
    for (final reply in replies) {
      list.add(
        _PostWithPriority(
          post: reply.copyWith(kind: PostKind.land, isTemporary: true),
          priority: priority,
          sortKey: reply.createdAt,
        ),
      );
    }
  }

  List<Post> _sortByPriority(List<_PostWithPriority> postsWithPriority) {
    postsWithPriority.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.sortKey.compareTo(b.sortKey);
    });
    return postsWithPriority.map((p) => p.post).toList();
  }

  void dispose() {
    _displayManager.dispose();
    _temporaryManager.dispose();
    _postsController?.close();
    _areaNameController?.close();
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
