import 'dart:async';

import 'package:openapi/openapi.dart';

/// 一時投稿（5秒で自動消滅する投稿）のデータモデル
///
/// 投稿本体と表示開始時刻を保持し、有効期限の判定に使用される。
class TemporaryPost {
  /// API投稿データ
  final APIPostOutput post;

  /// この投稿の表示が開始された日時
  final DateTime displayStartTime;

  /// TemporaryPostのコンストラクタ
  ///
  /// [post] API投稿データ
  /// [displayStartTime] 表示開始日時
  TemporaryPost({required this.post, required this.displayStartTime});
}

/// 一時投稿の管理を担当するクラス
///
/// 投稿作成時のレスポンス（返信や類似投稿）を一時的に表示するための管理クラス。
/// 各投稿は表示開始から5秒後に自動的に削除される。
/// クリーンアップタイマーにより、期限切れの投稿を定期的に削除する。
class TemporaryPostManager {
  /// 現在表示中の一時投稿リスト
  final List<TemporaryPost> _temporaryPosts = [];

  /// 定期的に期限切れ投稿を削除するタイマー
  Timer? _cleanupTimer;

  /// 一時投稿の表示期間（5秒）
  static const Duration temporaryPostLifetime = Duration(seconds: 5);

  /// クリーンアップの実行間隔（1秒ごと）
  static const Duration cleanupInterval = Duration(seconds: 1);

  /// クリーンアップタイマーを開始
  ///
  /// 定期的に期限切れの一時投稿を削除するタイマーを起動する。
  /// 既存のタイマーがある場合はキャンセルしてから新しいタイマーを開始する。
  ///
  /// [onChanged] 投稿リストが変更された際に呼び出されるコールバック
  void start(void Function() onChanged) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _cleanupExpiredPosts(onChanged);
    });
  }

  /// 期限切れの一時投稿を削除
  ///
  /// 現在時刻と各投稿の表示開始時刻を比較し、
  /// 有効期限（5秒）を超えた投稿を削除する。
  ///
  /// [onChanged] 投稿が削除された場合に呼び出されるコールバック
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
  ///
  /// 新しい一時投稿をリストに追加する。既に存在する投稿（UUID重複）は除外される。
  /// 追加された投稿は現在時刻から5秒後に自動削除される。
  ///
  /// [newPosts] 追加する投稿のリスト
  /// [onChanged] 投稿が追加された場合に呼び出されるコールバック
  void addTemporaryPosts(List<APIPostOutput> newPosts, void Function() onChanged) {
    final existingIds = _temporaryPosts.map((temp) => temp.post.uuid).toSet();
    final now = DateTime.now();
    final newTemporaryPosts = newPosts
        .where((post) => !existingIds.contains(post.uuid))
        .map((post) => TemporaryPost(post: post, displayStartTime: now));
    if (newTemporaryPosts.isNotEmpty) {
      _temporaryPosts.addAll(newTemporaryPosts);
      onChanged();
    }
  }

  /// すべての一時投稿を取得
  ///
  /// 現在表示中のすべての一時投稿のリストを返す。
  /// 期限切れチェックは行わず、クリーンアップタイマーに任せる。
  ///
  /// 戻り値: 一時投稿のリスト
  List<APIPostOutput> getTemporaryPosts() {
    return _temporaryPosts.map((temp) => temp.post).toList();
  }

  /// リソースを解放
  ///
  /// クリーンアップタイマーを停止し、リソースを解放する。
  /// このメソッド呼び出し後、このマネージャーは使用できなくなる。
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
