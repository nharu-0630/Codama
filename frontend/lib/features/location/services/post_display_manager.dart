import 'dart:async';

import 'package:openapi/openapi.dart';


/// 投稿の表示管理を担当するクラス
class PostDisplayManager {
  final List<APIPostOutput> _displayedPosts = []; // 画面に表示されている投稿
  final List<APIPostOutput> _pendingPosts = []; // 表示待ちキュー
  Timer? _displayTimer;

  static const Duration displayInterval = Duration(milliseconds: 500);

  /// 表示タイマーを開始
  void start(void Function() onChanged) {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(displayInterval, (_) {
      _displayNextPost(onChanged);
    });
  }

  /// 次の投稿を表示
  void _displayNextPost(void Function() onChanged) {
    if (_pendingPosts.isEmpty) {
      return;
    }
    final post = _pendingPosts.removeAt(0);
    _displayedPosts.add(post);
    onChanged();
  }

  /// キューに投稿を追加
  void addPostsToQueue(List<APIPostOutput> newPosts) {
    final existingIds = {
      ..._displayedPosts.map((p) => p.uuid),
      ..._pendingPosts.map((p) => p.uuid),
    };
    final uniquePosts = newPosts
        .where((p) => !existingIds.contains(p.uuid))
        .toList();
    if (uniquePosts.isNotEmpty) {
      _pendingPosts.addAll(uniquePosts);
    }
  }

  /// IDで投稿を削除
  void removePostById(String postId) {
    _displayedPosts.removeWhere((p) => p.uuid == postId);
    _pendingPosts.removeWhere((p) => p.uuid == postId);
  }

  /// 表示中の投稿を取得
  List<APIPostOutput> getDisplayedPosts() {
    return List.unmodifiable(_displayedPosts);
  }

  /// リソースを解放
  void dispose() {
    _displayTimer?.cancel();
  }
}
