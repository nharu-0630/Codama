import 'dart:async';

import '../../post/models/post.dart';

/// 一時投稿（5秒で消える投稿）を保持するクラス
class TemporaryPost {
  final Post post;
  final DateTime displayStartTime;

  TemporaryPost({required this.post, required this.displayStartTime});
}

/// 一時投稿の管理を担当するクラス
class TemporaryPostManager {
  final List<TemporaryPost> _temporaryPosts = [];
  Timer? _cleanupTimer;

  static const Duration temporaryPostLifetime = Duration(seconds: 5);
  static const Duration cleanupInterval = Duration(seconds: 1);

  /// クリーンアップタイマーを開始
  void start(void Function() onChanged) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _cleanupExpiredPosts(onChanged);
    });
  }

  /// 期限切れの一時投稿を削除
  void _cleanupExpiredPosts(void Function() onChanged) {
    final now = DateTime.now();
    final beforeCount = _temporaryPosts.length;
    _temporaryPosts.removeWhere((tempPost) {
      final elapsed = now.difference(tempPost.displayStartTime);
      return elapsed >= temporaryPostLifetime;
    });
    final removedCount = beforeCount - _temporaryPosts.length;
    if (removedCount > 0) {
      onChanged();
    }
  }

  /// 一時投稿を追加
  void addTemporaryPosts(List<Post> newPosts, void Function() onChanged) {
    final existingIds = _temporaryPosts.map((temp) => temp.post.id).toSet();
    final now = DateTime.now();
    final newTemporaryPosts = newPosts
        .where((post) => !existingIds.contains(post.id))
        .map((post) => TemporaryPost(post: post, displayStartTime: now));
    if (newTemporaryPosts.isNotEmpty) {
      _temporaryPosts.addAll(newTemporaryPosts);
      onChanged();
    }
  }

  /// すべての一時投稿を取得
  List<Post> getTemporaryPosts() {
    return _temporaryPosts.map((temp) => temp.post).toList();
  }

  /// リソースを解放
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
