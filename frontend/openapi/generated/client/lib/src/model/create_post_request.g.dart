// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePostRequest extends CreatePostRequest {
  @override
  final String content;
  @override
  final num lat;
  @override
  final num lon;

  factory _$CreatePostRequest(
          [void Function(CreatePostRequestBuilder)? updates]) =>
      (CreatePostRequestBuilder()..update(updates))._build();

  _$CreatePostRequest._(
      {required this.content, required this.lat, required this.lon})
      : super._();
  @override
  CreatePostRequest rebuild(void Function(CreatePostRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreatePostRequestBuilder toBuilder() =>
      CreatePostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePostRequest &&
        content == other.content &&
        lat == other.lat &&
        lon == other.lon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePostRequest')
          ..add('content', content)
          ..add('lat', lat)
          ..add('lon', lon))
        .toString();
  }
}

class CreatePostRequestBuilder
    implements Builder<CreatePostRequest, CreatePostRequestBuilder> {
  _$CreatePostRequest? _$v;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  num? _lat;
  num? get lat => _$this._lat;
  set lat(num? lat) => _$this._lat = lat;

  num? _lon;
  num? get lon => _$this._lon;
  set lon(num? lon) => _$this._lon = lon;

  CreatePostRequestBuilder() {
    CreatePostRequest._defaults(this);
  }

  CreatePostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _content = $v.content;
      _lat = $v.lat;
      _lon = $v.lon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePostRequest other) {
    _$v = other as _$CreatePostRequest;
  }

  @override
  void update(void Function(CreatePostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePostRequest build() => _build();

  _$CreatePostRequest _build() {
    final _$result = _$v ??
        _$CreatePostRequest._(
          content: BuiltValueNullFieldError.checkNotNull(
              content, r'CreatePostRequest', 'content'),
          lat: BuiltValueNullFieldError.checkNotNull(
              lat, r'CreatePostRequest', 'lat'),
          lon: BuiltValueNullFieldError.checkNotNull(
              lon, r'CreatePostRequest', 'lon'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
