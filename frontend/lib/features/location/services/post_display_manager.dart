import 'dart:async';

import 'package:codama/core/services/logger_service.dart';
import 'package:openapi/openapi.dart';

/// 投稿の表示管理を担当するクラス
///
/// 投稿を即座にすべて表示するのではなく、キューに追加して
/// 一定間隔（500ms）で1件ずつ順次表示することで、
/// ユーザーが投稿を読みやすくする。
class PostDisplayManager {
  /// 画面に表示されている投稿のリスト
  final List<APIPostOutput> _displayedPosts = [];

  /// 表示待ちのキュー
  final List<APIPostOutput> _pendingPosts = [];

  /// 定期的に投稿を表示するタイマー
  Timer? _displayTimer;

  /// ログサービス
  final LoggerService _logger;

  /// 投稿表示の間隔（500ミリ秒ごとに1件表示）
  static const Duration displayInterval = Duration(milliseconds: 500);

  /// PostDisplayManagerのコンストラクタ
  ///
  /// [logger] ログ出力用のサービス
  PostDisplayManager({required LoggerService logger}) : _logger = logger {
    _logger.d('PostDisplayManager初期化');
  }

  /// 表示タイマーを開始
  ///
  /// 定期的に（500msごとに）キューから投稿を取り出して表示する処理を開始する。
  ///
  /// [onChanged] 投稿が表示された際に呼び出されるコールバック
  void start(void Function() onChanged) {
    _logger.d('表示タイマー開始');
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(displayInterval, (_) {
      _displayNextPost(onChanged);
    });
  }

  /// 次の投稿を表示
  ///
  /// キューの先頭から1件取り出し、表示リストに追加する。
  /// キューが空の場合は何もしない。
  ///
  /// [onChanged] 投稿が表示された際に呼び出されるコールバック
  void _displayNextPost(void Function() onChanged) {
    if (_pendingPosts.isEmpty) {
      return;
    }
    final post = _pendingPosts.removeAt(0);
    _logger.d('投稿を表示: ${post.uuid}, 残りキュー: ${_pendingPosts.length}件');
    _displayedPosts.add(post);
    onChanged();
  }

  /// キューに投稿を追加
  ///
  /// 新しい投稿をキューに追加する。既に表示済みまたはキューに存在する投稿は除外される。
  ///
  /// [newPosts] 追加する投稿のリスト
  void addPostsToQueue(List<APIPostOutput> newPosts) {
    final existingIds = {
      ..._displayedPosts.map((p) => p.uuid),
      ..._pendingPosts.map((p) => p.uuid),
    };
    final uniquePosts = newPosts
        .where((p) => !existingIds.contains(p.uuid))
        .toList();
    if (uniquePosts.isNotEmpty) {
      _logger.d('${uniquePosts.length}件の投稿をキューに追加');
      _pendingPosts.addAll(uniquePosts);
    }
  }

  /// IDで投稿を削除
  ///
  /// 指定されたIDの投稿を表示リストとキューの両方から削除する。
  /// Optimistic UI の仮投稿を削除する際などに使用される。
  ///
  /// [postId] 削除する投稿のID
  void removePostById(String postId) {
    _logger.d('投稿を削除: $postId');
    _displayedPosts.removeWhere((p) => p.uuid == postId);
    _pendingPosts.removeWhere((p) => p.uuid == postId);
  }

  /// 表示中の投稿を取得
  ///
  /// 現在画面に表示されているすべての投稿のリストを返す。
  /// 変更不可能なリストとして返されるため、直接操作できない。
  ///
  /// 戻り値: 表示中の投稿リスト
  List<APIPostOutput> getDisplayedPosts() {
    return List.unmodifiable(_displayedPosts);
  }

  /// リソースを解放
  ///
  /// タイマーを停止し、リソースを解放する。
  void dispose() {
    _logger.d('PostDisplayManager破棄');
    _displayTimer?.cancel();
  }
}
