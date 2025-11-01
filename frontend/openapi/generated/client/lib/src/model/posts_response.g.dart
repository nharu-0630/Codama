// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PostsResponse extends PostsResponse {
  @override
  final BuiltList<APIPostOutput> posts;

  factory _$PostsResponse([void Function(PostsResponseBuilder)? updates]) =>
      (PostsResponseBuilder()..update(updates))._build();

  _$PostsResponse._({required this.posts}) : super._();
  @override
  PostsResponse rebuild(void Function(PostsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PostsResponseBuilder toBuilder() => PostsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostsResponse && posts == other.posts;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, posts.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostsResponse')..add('posts', posts))
        .toString();
  }
}

class PostsResponseBuilder
    implements Builder<PostsResponse, PostsResponseBuilder> {
  _$PostsResponse? _$v;

  ListBuilder<APIPostOutput>? _posts;
  ListBuilder<APIPostOutput> get posts =>
      _$this._posts ??= ListBuilder<APIPostOutput>();
  set posts(ListBuilder<APIPostOutput>? posts) => _$this._posts = posts;

  PostsResponseBuilder() {
    PostsResponse._defaults(this);
  }

  PostsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _posts = $v.posts.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostsResponse other) {
    _$v = other as _$PostsResponse;
  }

  @override
  void update(void Function(PostsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PostsResponse build() => _build();

  _$PostsResponse _build() {
    _$PostsResponse _$result;
    try {
      _$result = _$v ??
          _$PostsResponse._(
            posts: posts.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'posts';
        posts.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PostsResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
