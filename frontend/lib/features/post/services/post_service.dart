import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

/// 投稿サービス - API/モック両対応
class PostService {
  static const String _baseUrl = 'http://localhost:8000';
  static const bool _useApi = false; // TODO: 本番時はtrueに変更
  static const int _maxPosts = 100; // 最大保持投稿数

  // モックデータ（ローカル開発用）
  final List<Post> _mockPosts = [];

  /// サービス初期化
  Future<void> initialize() async {
    if (!_useApi) {
      // モックデータ追加
      await _addDemoData();
    }
  }

  /// リソースクリーンアップ
  Future<void> dispose() async {
    if (!_useApi) {
      _mockPosts.clear();
    }
  }

  /// 投稿作成
  Future<Post> createPost({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    if (_useApi) {
      return _createPostApi(lat: lat, lng: lng, text: text, userId: userId);
    } else {
      return _createPostMock(lat: lat, lng: lng, text: text, userId: userId);
    }
  }

  /// 投稿取得
  Future<List<Post>> getAllPosts() async {
    if (_useApi) {
      return _getPostsApi();
    } else {
      return _getPostsMock();
    }
  }

  /// 投稿削除
  Future<void> deletePost(String postId) async {
    if (_useApi) {
      await _deletePostApi(postId);
    } else {
      _deletePostMock(postId);
    }
  }

  // =============
  // モック実装
  // =============

  Future<Post> _createPostMock({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    // API遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: lat,
      lng: lng,
      kind: PostKind.user,
      text: text,
      createdAt: DateTime.now(),
      userId: userId,
    );
    
    _mockPosts.add(post);
    
    // 最大投稿数を超えたら古い投稿を削除
    _trimOldPosts();
    
    return post;
  }

  Future<List<Post>> _getPostsMock() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_mockPosts);
  }

  void _deletePostMock(String postId) {
    _mockPosts.removeWhere((post) => post.id == postId);
  }

  Future<void> _addDemoData() async {
    // 横浜駅周辺の30件のデモデータ
    final demoMessages = [
      'こんにちは！横浜駅です',
      'この場所は人が多いですね',
      '良い天気です！',
      'ここでランチを食べました',
      '電車が遅れているみたい',
      'イベントやってる！',
      '新しいお店ができてる',
      '工事中で通りにくいです',
      '桜が綺麗に咲いています',
      '雨が降ってきました',
      'ここで待ち合わせしてます',
      '迷子になりました...',
      '素敵なカフェ見つけた！',
      '混雑してます',
      'WiFiが使えますよ',
      '景色がいいですね',
      '静かで落ち着きます',
      '昔ここに来たことがある',
      'おすすめのスポットです',
      '夜景が綺麗！',
      '朝の散歩に最適',
      'ここで休憩中',
      '友達と遊んでます',
      '初めて来ました',
      '懐かしい場所',
      '写真撮影スポット',
      'ペットも入れます',
      '子供が遊べる場所',
      'バリアフリー対応',
      '今日は空いてる',
    ];

    // 横浜駅を中心に半径500m程度の範囲でランダムに配置
    final baseLatitude = 35.4658;
    final baseLongitude = 139.6201;
    final random = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < demoMessages.length; i++) {
      // ランダムな位置を生成（約±0.0045度 = 約±500m）
      final latOffset = (i * 7 % 20 - 10) * 0.00045;
      final lngOffset = ((i + 3) * 11 % 20 - 10) * 0.00045;

      await _createPostMock(
        lat: baseLatitude + latOffset,
        lng: baseLongitude + lngOffset,
        text: demoMessages[i],
      );

      // 少し遅延を入れて作成時刻に差をつける
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// 古い投稿を削除して最大投稿数を維持
  void _trimOldPosts() {
    if (_mockPosts.length > _maxPosts) {
      // 作成日時でソート（古い順）
      _mockPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // 古い投稿を削除
      final removeCount = _mockPosts.length - _maxPosts;
      _mockPosts.removeRange(0, removeCount);
    }
  }

  // =============
  // API実装
  // =============

  Future<Post> _createPostApi({
    required double lat,
    required double lng,
    required String text,
    String? userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/posts');
    
    final requestBody = {
      'lat': lat,
      'lng': lng,
      'content': text,
      'kind': 'user',
      if (userId != null) 'user_id': userId,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return _parsePostFromApi(responseData);
    } else {
      throw Exception('投稿の作成に失敗しました: ${response.statusCode}');
    }
  }

  Future<List<Post>> _getPostsApi() async {
    final uri = Uri.parse('$_baseUrl/posts');
    
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => _parsePostFromApi(data)).toList();
    } else {
      throw Exception('投稿の取得に失敗しました: ${response.statusCode}');
    }
  }

  Future<void> _deletePostApi(String postId) async {
    final uri = Uri.parse('$_baseUrl/posts/$postId');
    
    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('投稿の削除に失敗しました: ${response.statusCode}');
    }
  }

  Post _parsePostFromApi(Map<String, dynamic> data) {
    return Post(
      id: data['id'].toString(),
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      kind: data['kind'] == 'user' ? PostKind.user : PostKind.land,
      text: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      userId: data['user_id'] as String?,
    );
  }
}