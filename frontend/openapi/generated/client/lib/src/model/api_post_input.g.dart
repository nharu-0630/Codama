// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_post_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$APIPostInput extends APIPostInput {
  @override
  final APIArea? area;
  @override
  final APICell? cell;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final BuiltList<JsonObject?> location;
  @override
  final BuiltList<APIPostInput>? replies;
  @override
  final String? userUuid;
  @override
  final String uuid;

  factory _$APIPostInput([void Function(APIPostInputBuilder)? updates]) =>
      (APIPostInputBuilder()..update(updates))._build();

  _$APIPostInput._(
      {this.area,
      this.cell,
      required this.content,
      required this.createdAt,
      required this.location,
      this.replies,
      this.userUuid,
      required this.uuid})
      : super._();
  @override
  APIPostInput rebuild(void Function(APIPostInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  APIPostInputBuilder toBuilder() => APIPostInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is APIPostInput &&
        area == other.area &&
        cell == other.cell &&
        content == other.content &&
        createdAt == other.createdAt &&
        location == other.location &&
        replies == other.replies &&
        userUuid == other.userUuid &&
        uuid == other.uuid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, area.hashCode);
    _$hash = $jc(_$hash, cell.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, replies.hashCode);
    _$hash = $jc(_$hash, userUuid.hashCode);
    _$hash = $jc(_$hash, uuid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'APIPostInput')
          ..add('area', area)
          ..add('cell', cell)
          ..add('content', content)
          ..add('createdAt', createdAt)
          ..add('location', location)
          ..add('replies', replies)
          ..add('userUuid', userUuid)
          ..add('uuid', uuid))
        .toString();
  }
}

class APIPostInputBuilder
    implements Builder<APIPostInput, APIPostInputBuilder> {
  _$APIPostInput? _$v;

  APIAreaBuilder? _area;
  APIAreaBuilder get area => _$this._area ??= APIAreaBuilder();
  set area(APIAreaBuilder? area) => _$this._area = area;

  APICellBuilder? _cell;
  APICellBuilder get cell => _$this._cell ??= APICellBuilder();
  set cell(APICellBuilder? cell) => _$this._cell = cell;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ListBuilder<JsonObject?>? _location;
  ListBuilder<JsonObject?> get location =>
      _$this._location ??= ListBuilder<JsonObject?>();
  set location(ListBuilder<JsonObject?>? location) =>
      _$this._location = location;

  ListBuilder<APIPostInput>? _replies;
  ListBuilder<APIPostInput> get replies =>
      _$this._replies ??= ListBuilder<APIPostInput>();
  set replies(ListBuilder<APIPostInput>? replies) => _$this._replies = replies;

  String? _userUuid;
  String? get userUuid => _$this._userUuid;
  set userUuid(String? userUuid) => _$this._userUuid = userUuid;

  String? _uuid;
  String? get uuid => _$this._uuid;
  set uuid(String? uuid) => _$this._uuid = uuid;

  APIPostInputBuilder() {
    APIPostInput._defaults(this);
  }

  APIPostInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _area = $v.area?.toBuilder();
      _cell = $v.cell?.toBuilder();
      _content = $v.content;
      _createdAt = $v.createdAt;
      _location = $v.location.toBuilder();
      _replies = $v.replies?.toBuilder();
      _userUuid = $v.userUuid;
      _uuid = $v.uuid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(APIPostInput other) {
    _$v = other as _$APIPostInput;
  }

  @override
  void update(void Function(APIPostInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  APIPostInput build() => _build();

  _$APIPostInput _build() {
    _$APIPostInput _$result;
    try {
      _$result = _$v ??
          _$APIPostInput._(
            area: _area?.build(),
            cell: _cell?.build(),
            content: BuiltValueNullFieldError.checkNotNull(
                content, r'APIPostInput', 'content'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'APIPostInput', 'createdAt'),
            location: location.build(),
            replies: _replies?.build(),
            userUuid: userUuid,
            uuid: BuiltValueNullFieldError.checkNotNull(
                uuid, r'APIPostInput', 'uuid'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'area';
        _area?.build();
        _$failedField = 'cell';
        _cell?.build();

        _$failedField = 'location';
        location.build();
        _$failedField = 'replies';
        _replies?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'APIPostInput', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
