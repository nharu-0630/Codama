import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:openapi/openapi.dart';

import 'post_display_manager.dart';
import 'temporary_post_manager.dart';

/// セルトラッキングサービス
///
/// ユーザーの位置に基づいてセル（地理的エリアの区分単位）を追跡し、
/// セル移動時に新しい投稿データを取得・管理する。
/// 投稿の表示管理（順次表示）と一時投稿（5秒で消滅）を制御する。
class CellTrackingService {
  /// APIサービス
  final ApiService _apiService;

  /// ログサービス
  final LoggerService _logger;

  /// 投稿の順次表示を管理するマネージャー
  final PostDisplayManager _displayManager;

  /// 一時投稿（5秒で消える）を管理するマネージャー
  final TemporaryPostManager _temporaryManager;

  /// CellTrackingServiceのコンストラクタ
  ///
  /// [apiService] バックエンドとの通信を行うAPIサービス
  /// [logger] ログ出力用のサービス
  CellTrackingService({
    required ApiService apiService,
    required LoggerService logger,
  })  : _apiService = apiService,
        _logger = logger,
        _displayManager = PostDisplayManager(logger: logger),
        _temporaryManager = TemporaryPostManager() {
    _logger.d('CellTrackingService初期化');
  }

  /// 現在いるセル
  APICell? _currentCell;

  /// 現在のエリア名
  String? _currentAreaName;

  /// 投稿リストのストリームコントローラー
  StreamController<List<APIPostOutput>>? _postsController;

  /// エリア名のストリームコントローラー
  StreamController<String?>? _areaNameController;

  /// 投稿リストのストリーム
  Stream<List<APIPostOutput>>? get postsStream => _postsController?.stream;

  /// エリア名のストリーム
  Stream<String?>? get areaNameStream => _areaNameController?.stream;

  /// 現在のエリア名を取得
  String? get currentAreaName => _currentAreaName;

  // ==================== 投稿表示の優先度定数 ====================

  /// 作成投稿の返信（最優先）
  static const int _priorityCreatedPostReplies = 1;

  /// 類似投稿
  static const int _prioritySimilarPosts = 2;

  /// 類似投稿の返信
  static const int _prioritySimilarPostReplies = 3;

  /// サービスの初期化
  ///
  /// 認証状態を確認し、未認証の場合は自動サインアップを実行する。
  /// ストリームコントローラーと各マネージャーを初期化する。
  Future<void> initialize() async {
    _logger.i('CellTrackingService初期化開始');

    final isAuthenticated = _apiService.isAuthenticated();
    if (!isAuthenticated) {
      _logger.i('未認証のため、自動サインアップを実行');
      await _apiService.signUp();
    }

    _postsController = StreamController<List<APIPostOutput>>.broadcast();
    _areaNameController = StreamController<String?>.broadcast();
    _displayManager.start(_broadcastAllPosts);
    _temporaryManager.start(_broadcastAllPosts);

    _logger.i('CellTrackingService初期化完了');
  }

  /// すべての投稿をブロードキャスト
  ///
  /// 表示中の投稿と一時投稿を結合してストリームに送信する。
  void _broadcastAllPosts() {
    final allPosts = [
      ..._displayManager.getDisplayedPosts(),
      ..._temporaryManager.getTemporaryPosts(),
    ];
    _logger.d('投稿をブロードキャスト: ${allPosts.length}件');
    _postsController?.add(allPosts);
  }

  /// 位置変更時の処理
  ///
  /// ユーザーの位置が変わった際に呼び出され、現在地のエリアとセル情報を取得する。
  /// セルが変わった場合は、新しいセルの投稿データを取得して表示キューに追加する。
  ///
  /// [loc] 新しい位置座標
  Future<void> onLocationChanged(LatLng loc) async {
    try {
      _logger.d('位置変更検出: $loc');

      final current = await _apiService.getCurrentLocation(
        loc.latitude,
        loc.longitude,
      );
      if (current == null) {
        _logger.w('現在地情報の取得に失敗');
        return;
      }

      // エリア名が変わったら通知
      if (_currentAreaName != current.area.name) {
        _logger.i('エリア変更: $_currentAreaName -> ${current.area.name}');
        _currentAreaName = current.area.name;
        _areaNameController?.add(_currentAreaName);
      }

      // セルが変わったら投稿を取得
      if (_currentCell == null ||
          !_areCellsEqual(_currentCell!, current.cell)) {
        _logger.i('セル変更検出: ${_currentCell?.id} -> ${current.cell.id}');
        _currentCell = current.cell;

        final postsResponse = await _apiService.getPostsByLocation(
          loc.latitude,
          loc.longitude,
        );
        _logger.i('新しいセルの投稿を取得: ${postsResponse.posts.length}件');
        _addPostsToQueue(postsResponse.posts.toList());
      }
    } catch (e) {
      _logger.e('位置変更処理中にエラー', e);
    }
  }

  /// 2つのセルが同じかどうかを判定
  ///
  /// [cell1] 比較するセル1
  /// [cell2] 比較するセル2
  /// 戻り値: 同じセルの場合true
  bool _areCellsEqual(APICell cell1, APICell cell2) {
    return cell1.id == cell2.id && cell1.geoHash == cell2.geoHash;
  }

  /// 投稿を表示キューに追加
  ///
  /// [newPosts] 追加する投稿のリスト
  void _addPostsToQueue(List<APIPostOutput> newPosts) {
    _logger.d('${newPosts.length}件の投稿をキューに追加');
    _displayManager.addPostsToQueue(newPosts);
  }

  /// 一時投稿を追加
  ///
  /// [newPosts] 追加する一時投稿のリスト
  void _addTemporaryPosts(List<APIPostOutput> newPosts) {
    _logger.d('${newPosts.length}件の一時投稿を追加');
    _temporaryManager.addTemporaryPosts(newPosts, _broadcastAllPosts);
  }

  /// 投稿を作成
  ///
  /// ユーザーの投稿をバックエンドに送信し、レスポンス（返信や類似投稿）を処理する。
  /// Optimistic UI（楽観的UI）パターンを使用し、サーバーレスポンスを待たずに
  /// 一時的な投稿を表示することでUXを向上させる。
  ///
  /// [loc] 投稿位置
  /// [text] 投稿内容
  Future<void> createPost({required LatLng loc, required String text}) async {
    _logger.i('投稿作成開始: "$text" at $loc');

    final currentUserId = _apiService.getCurrentUserId();
    if (currentUserId == null) {
      _logger.w('ユーザーIDがnullのため、投稿を作成できません');
      return;
    }

    // Optimistic UI: サーバーレスポンスを待たずに仮の投稿を表示
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

    _logger.d('Optimistic投稿を追加: $optimisticPostId');
    _displayManager.addPostsToQueue([optimisticPost]);

    try {
      final response = await _apiService.createPost(
        lat: loc.latitude,
        lng: loc.longitude,
        text: text,
      );

      _logger.i('投稿作成成功: postId=${response.post.uuid}');

      // レスポンスから返信と類似投稿を展開
      final responsePosts = await _flattenResponsePosts(
        response.post,
        response.similarPosts.toList(),
      );
      _logger.d('レスポンス投稿を展開: ${responsePosts.length}件');

      // 一時投稿として追加（5秒で消える）
      _addTemporaryPosts(responsePosts);
      // 実際の投稿をキューに追加
      _addPostsToQueue([response.post]);
    } catch (e) {
      _logger.e('投稿作成に失敗', e);
    } finally {
      // Optimistic投稿を削除
      _logger.d('Optimistic投稿を削除: $optimisticPostId');
      _displayManager.removePostById(optimisticPostId);
      _broadcastAllPosts();
    }
  }

  /// レスポンスから投稿を優先度順に展開
  ///
  /// 投稿作成時のレスポンスには、作成した投稿への返信と類似投稿が含まれる。
  /// これらを優先度順に並び替えて1つのリストにフラット化する。
  ///
  /// 優先度:
  /// 1. 作成投稿の返信（最優先）
  /// 2. 類似投稿
  /// 3. 類似投稿の返信
  /// 各優先度内では古い順（作成日時順）にソートされる。
  ///
  /// [createdPost] 作成された投稿
  /// [similarPosts] 類似投稿のリスト
  /// 戻り値: 優先度順にソートされた投稿リスト
  Future<List<APIPostOutput>> _flattenResponsePosts(
    APIPostOutput createdPost,
    List<APIPostOutput> similarPosts,
  ) async {
    final postsWithPriority = <_PostWithPriority>[];

    // 1. 作成された投稿への返信を追加
    final createdRepliesCount = createdPost.replies?.length ?? 0;
    _logger.d('作成投稿の返信: $createdRepliesCount件');
    _addRepliesToList(
      postsWithPriority,
      createdPost.replies?.toList() ?? [],
      _priorityCreatedPostReplies,
    );

    // 2. 類似投稿とその返信を追加
    _logger.d('類似投稿: ${similarPosts.length}件');
    for (final similarPost in similarPosts) {
      postsWithPriority.add(
        _PostWithPriority(
          post: similarPost,
          priority: _prioritySimilarPosts,
          sortKey: similarPost.createdAt,
        ),
      );

      final similarRepliesCount = similarPost.replies?.length ?? 0;
      _logger.d('類似投稿 ${similarPost.uuid} の返信: $similarRepliesCount件');
      _addRepliesToList(
        postsWithPriority,
        similarPost.replies?.toList() ?? [],
        _prioritySimilarPostReplies,
      );
    }

    final sortedPosts = _sortByPriority(postsWithPriority);
    _logger.d('投稿を優先度順にソート完了: ${sortedPosts.length}件');
    return sortedPosts;
  }

  /// 返信リストを優先度付きリストに追加
  ///
  /// [list] 追加先の優先度付きリスト
  /// [replies] 追加する返信のリスト
  /// [priority] 優先度
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

  /// 優先度順にソート
  ///
  /// まず優先度でソートし、優先度が同じ場合は作成日時（古い順）でソートする。
  ///
  /// [postsWithPriority] ソート対象の優先度付き投稿リスト
  /// 戻り値: ソート済みの投稿リスト
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

  /// リソースを解放
  ///
  /// サービスを破棄する際に呼び出し、すべてのリソースを解放する。
  void dispose() {
    _logger.d('CellTrackingService破棄');
    _displayManager.dispose();
    _temporaryManager.dispose();
    _postsController?.close();
    _areaNameController?.close();
  }
}

/// 投稿と優先度を保持する内部クラス
///
/// 投稿のソート処理で使用され、優先度とソートキーを持つ。
class _PostWithPriority {
  /// 投稿データ
  final APIPostOutput post;

  /// 優先度（数字が小さいほど優先度が高い）
  final int priority;

  /// ソートキー（作成日時）
  final DateTime sortKey;

  /// _PostWithPriorityのコンストラクタ
  ///
  /// [post] 投稿データ
  /// [priority] 優先度
  /// [sortKey] ソートキー
  _PostWithPriority({
    required this.post,
    required this.priority,
    required this.sortKey,
  });
}
