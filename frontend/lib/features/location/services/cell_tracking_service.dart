import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:openapi/openapi.dart';

import 'post_display_manager.dart';
import 'temporary_post_manager.dart';

class CellTrackingService {
  final ApiService _apiService;
  final PostDisplayManager _displayManager = PostDisplayManager();
  final TemporaryPostManager _temporaryManager = TemporaryPostManager();

  CellTrackingService({required ApiService apiService})
    : _apiService = apiService;

  APICell? _currentCell;
  String? _currentAreaName;
  StreamController<List<APIPostOutput>>? _postsController;
  StreamController<String?>? _areaNameController;

  Stream<List<APIPostOutput>>? get postsStream => _postsController?.stream;
  Stream<String?>? get areaNameStream => _areaNameController?.stream;
  String? get currentAreaName => _currentAreaName;

  // 投稿表示の優先度定数
  static const int _priorityCreatedPostReplies = 1; // 作成投稿の返信（最優先）
  static const int _prioritySimilarPosts = 2; // 類似投稿
  static const int _prioritySimilarPostReplies = 3; // 類似投稿の返信

  Future<void> initialize() async {
    final isAuthenticated = _apiService.isAuthenticated();
    if (!isAuthenticated) {
      await _apiService.signUp();
    }

    _postsController = StreamController<List<APIPostOutput>>.broadcast();
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
      final current = await _apiService.getCurrentLocation(
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

      if (_currentCell == null ||
          !_areCellsEqual(_currentCell!, current.cell)) {
        _currentCell = current.cell;
        final postsResponse = await _apiService.getPostsByLocation(
          loc.latitude,
          loc.longitude,
        );
        _addPostsToQueue(postsResponse.posts.toList());
      }
    } catch (e) {
      // 位置情報の取得に失敗した場合は何もしない
    }
  }

  bool _areCellsEqual(APICell cell1, APICell cell2) {
    return cell1.id == cell2.id && cell1.geoHash == cell2.geoHash;
  }

  void _addPostsToQueue(List<APIPostOutput> newPosts) {
    _displayManager.addPostsToQueue(newPosts);
  }

  void _addTemporaryPosts(List<APIPostOutput> newPosts) {
    _temporaryManager.addTemporaryPosts(newPosts, _broadcastAllPosts);
  }

  Future<void> createPost({required LatLng loc, required String text}) async {
    final currentUserId = _apiService.getCurrentUserId();
    if (currentUserId == null) return;

    // Create optimistic post using APIPostOutput structure
    final optimisticPostId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticPost = APIPostOutput(
      (b) => b
        ..uuid = optimisticPostId
        ..content = text
        ..createdAt = DateTime.now()
        ..location.addAll([JsonObject(loc.latitude), JsonObject(loc.longitude)])
        ..userUuid = currentUserId
        ..replies = ListBuilder<APIPostOutput>(),
    );

    _displayManager.addPostsToQueue([optimisticPost]);
    try {
      final response = await _apiService.createPost(
        lat: loc.latitude,
        lng: loc.longitude,
        text: text,
      );

      final responsePosts = await _flattenResponsePosts(
        response.post,
        response.similarPosts.toList(),
      );
      _addTemporaryPosts(responsePosts);
      _addPostsToQueue([response.post]);
    } catch (e) {
      // 投稿作成に失敗した場合は何もしない
    } finally {
      _displayManager.removePostById(optimisticPostId);
      _broadcastAllPosts();
    }
  }

  /// レスポンスから投稿を優先度順に展開
  /// 優先度: 1.作成投稿の返信 2.類似投稿 3.類似投稿の返信（各優先度内では古い順）
  Future<List<APIPostOutput>> _flattenResponsePosts(
    APIPostOutput createdPost,
    List<APIPostOutput> similarPosts,
  ) async {
    final postsWithPriority = <_PostWithPriority>[];

    // 1. 作成された投稿への返信を追加
    _addRepliesToList(
      postsWithPriority,
      createdPost.replies?.toList() ?? [],
      _priorityCreatedPostReplies,
    );

    // 2. 類似投稿とその返信を追加
    for (final similarPost in similarPosts) {
      postsWithPriority.add(
        _PostWithPriority(
          post: similarPost,
          priority: _prioritySimilarPosts,
          sortKey: similarPost.createdAt,
        ),
      );

      _addRepliesToList(
        postsWithPriority,
        similarPost.replies?.toList() ?? [],
        _prioritySimilarPostReplies,
      );
    }

    return _sortByPriority(postsWithPriority);
  }

  void _addRepliesToList(
    List<_PostWithPriority> list,
    List<APIPostOutput> replies,
    int priority,
  ) {
    for (final reply in replies) {
      list.add(
        _PostWithPriority(
          post: reply,
          priority: priority,
          sortKey: reply.createdAt,
        ),
      );
    }
  }

  List<APIPostOutput> _sortByPriority(
    List<_PostWithPriority> postsWithPriority,
  ) {
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
  final APIPostOutput post;
  final int priority;
  final DateTime sortKey;

  _PostWithPriority({
    required this.post,
    required this.priority,
    required this.sortKey,
  });
}
