import 'dart:async';

import '../../post/models/post.dart';

/// 投稿の表示管理を担当するクラス
class PostDisplayManager {
  final List<Post> _displayedPosts = []; // 画面に表示されている投稿
  final List<Post> _pendingPosts = []; // 表示待ちキュー
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
  void addPostsToQueue(List<Post> newPosts) {
    final existingIds = {
      ..._displayedPosts.map((p) => p.id),
      ..._pendingPosts.map((p) => p.id),
    };
    final uniquePosts = newPosts
        .where((p) => !existingIds.contains(p.id))
        .toList();
    if (uniquePosts.isNotEmpty) {
      _pendingPosts.addAll(uniquePosts);
    }
  }

  /// IDで投稿を削除
  void removePostById(String postId) {
    _displayedPosts.removeWhere((p) => p.id == postId);
    _pendingPosts.removeWhere((p) => p.id == postId);
  }

  /// 表示中の投稿を取得
  List<Post> getDisplayedPosts() {
    return List.unmodifiable(_displayedPosts);
  }

  /// リソースを解放
  void dispose() {
    _displayTimer?.cancel();
  }
}
