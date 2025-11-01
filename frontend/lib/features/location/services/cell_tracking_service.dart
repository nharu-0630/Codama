import 'dart:async';

import 'package:latlong2/latlong.dart';
import '../../../domain/entities/location_data.dart';
import '../../../domain/entities/post.dart' as domain;
import '../../../domain/usecases/auth/auth_use_case.dart';
import '../../../domain/usecases/location/location_use_case.dart';
import '../../../domain/usecases/post/post_use_case.dart';
import 'post_display_manager.dart';
import 'temporary_post_manager.dart';

class CellTrackingService {
  final AuthUseCase _authUseCase;
  final LocationUseCase _locationUseCase;
  final PostUseCase _postUseCase;
  final PostDisplayManager _displayManager = PostDisplayManager();
  final TemporaryPostManager _temporaryManager = TemporaryPostManager();

  CellTrackingService({
    required AuthUseCase authUseCase,
    required LocationUseCase locationUseCase,
    required PostUseCase postUseCase,
  }) : _authUseCase = authUseCase,
       _locationUseCase = locationUseCase,
       _postUseCase = postUseCase;

  Cell? _currentCell;
  String? _currentAreaName;
  StreamController<List<domain.Post>>? _postsController;
  StreamController<String?>? _areaNameController;

  Stream<List<domain.Post>>? get postsStream => _postsController?.stream;
  Stream<String?>? get areaNameStream => _areaNameController?.stream;
  String? get currentAreaName => _currentAreaName;

  // 投稿表示の優先度定数
  static const int _priorityCreatedPostReplies = 1; // 作成投稿の返信（最優先）
  static const int _prioritySimilarPosts = 2; // 類似投稿
  static const int _prioritySimilarPostReplies = 3; // 類似投稿の返信

  Future<void> initialize() async {
    final isAuthenticated = await _authUseCase.isAuthenticated();
    if (!isAuthenticated) {
      await _authUseCase.signUp();
    }

    _postsController = StreamController<List<domain.Post>>.broadcast();
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
      final current = await _locationUseCase.getCurrentLocation(
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
        final domainPosts = await _postUseCase.getPostsByLocation(
          loc.latitude,
          loc.longitude,
        );
        _addPostsToQueue(domainPosts);
      }
    } catch (e) {
      // 位置情報の取得に失敗した場合は何もしない
    }
  }

  void _addPostsToQueue(List<domain.Post> newPosts) {
    _displayManager.addPostsToQueue(newPosts);
  }

  void _addTemporaryPosts(List<domain.Post> newPosts) {
    _temporaryManager.addTemporaryPosts(newPosts, _broadcastAllPosts);
  }

  Future<void> createPost({required LatLng loc, required String text}) async {
    final currentUser = await _authUseCase.getCurrentUser();
    final optimisticPost = domain.Post.fromApiResponse({
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'lat': loc.latitude,
      'lng': loc.longitude,
      'kind': 'user',
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
      'user_id': currentUser.id,
      'is_temporary': false,
      'replies': [],
    });
    _displayManager.addPostsToQueue([optimisticPost]);
    try {
      final result = await _postUseCase.createPost(
        lat: loc.latitude,
        lng: loc.longitude,
        text: text,
      );
      final domainPost = result['post'] as domain.Post;
      final domainSimilarPosts = result['similar_posts'] as List<domain.Post>;
      
      final responsePosts = await _flattenResponsePosts(domainPost, domainSimilarPosts);
      _addTemporaryPosts(responsePosts);
      _addPostsToQueue([domainPost]);
    } catch (e) {
      // 投稿作成に失敗した場合は何もしない
    } finally {
      _displayManager.removePostById(optimisticPost.id);
      _broadcastAllPosts();
    }
  }

  /// レスポンスから投稿を優先度順に展開
  /// 優先度: 1.作成投稿の返信 2.類似投稿 3.類似投稿の返信（各優先度内では古い順）
  Future<List<domain.Post>> _flattenResponsePosts(domain.Post createdPost, List<domain.Post> similarPosts) async {
    final postsWithPriority = <_PostWithPriority>[];

    // 作成された投稿（一時投稿として5秒で消える）
    final currentUser = await _authUseCase.getCurrentUser();
    final temporaryCreatedPost = _makeTemporaryPost(
      createdPost,
      userId: currentUser.id,
    );

    // 1. 作成された投稿への返信を追加
    _addRepliesToList(
      postsWithPriority,
      temporaryCreatedPost.replies,
      _priorityCreatedPostReplies,
    );

    // 2. 類似投稿とその返信を追加
    for (final similarPost in similarPosts) {
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

  domain.Post _makeTemporaryPost(domain.Post post, {String? userId}) {
    return post.copyWith(userId: userId ?? post.userId, isTemporary: true);
  }

  void _addRepliesToList(
    List<_PostWithPriority> list,
    List<domain.Post> replies,
    int priority,
  ) {
    for (final reply in replies) {
      list.add(
        _PostWithPriority(
          post: reply.copyWith(kind: domain.PostKind.land, isTemporary: true),
          priority: priority,
          sortKey: reply.createdAt,
        ),
      );
    }
  }

  List<domain.Post> _sortByPriority(List<_PostWithPriority> postsWithPriority) {
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
  final domain.Post post;
  final int priority;
  final DateTime sortKey;

  _PostWithPriority({
    required this.post,
    required this.priority,
    required this.sortKey,
  });
}
