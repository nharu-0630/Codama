// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePostResponse extends CreatePostResponse {
  @override
  final APIPostOutput post;
  @override
  final BuiltList<APIPostOutput> similarPosts;

  factory _$CreatePostResponse(
          [void Function(CreatePostResponseBuilder)? updates]) =>
      (CreatePostResponseBuilder()..update(updates))._build();

  _$CreatePostResponse._({required this.post, required this.similarPosts})
      : super._();
  @override
  CreatePostResponse rebuild(
          void Function(CreatePostResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreatePostResponseBuilder toBuilder() =>
      CreatePostResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePostResponse &&
        post == other.post &&
        similarPosts == other.similarPosts;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, post.hashCode);
    _$hash = $jc(_$hash, similarPosts.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePostResponse')
          ..add('post', post)
          ..add('similarPosts', similarPosts))
        .toString();
  }
}

class CreatePostResponseBuilder
    implements Builder<CreatePostResponse, CreatePostResponseBuilder> {
  _$CreatePostResponse? _$v;

  APIPostOutputBuilder? _post;
  APIPostOutputBuilder get post => _$this._post ??= APIPostOutputBuilder();
  set post(APIPostOutputBuilder? post) => _$this._post = post;

  ListBuilder<APIPostOutput>? _similarPosts;
  ListBuilder<APIPostOutput> get similarPosts =>
      _$this._similarPosts ??= ListBuilder<APIPostOutput>();
  set similarPosts(ListBuilder<APIPostOutput>? similarPosts) =>
      _$this._similarPosts = similarPosts;

  CreatePostResponseBuilder() {
    CreatePostResponse._defaults(this);
  }

  CreatePostResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _post = $v.post.toBuilder();
      _similarPosts = $v.similarPosts.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePostResponse other) {
    _$v = other as _$CreatePostResponse;
  }

  @override
  void update(void Function(CreatePostResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePostResponse build() => _build();

  _$CreatePostResponse _build() {
    _$CreatePostResponse _$result;
    try {
      _$result = _$v ??
          _$CreatePostResponse._(
            post: post.build(),
            similarPosts: similarPosts.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'post';
        post.build();
        _$failedField = 'similarPosts';
        similarPosts.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CreatePostResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
