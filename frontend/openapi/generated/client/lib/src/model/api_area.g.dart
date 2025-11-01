// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_area.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$APIArea extends APIArea {
  @override
  final int id;
  @override
  final String name;

  factory _$APIArea([void Function(APIAreaBuilder)? updates]) =>
      (APIAreaBuilder()..update(updates))._build();

  _$APIArea._({required this.id, required this.name}) : super._();
  @override
  APIArea rebuild(void Function(APIAreaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  APIAreaBuilder toBuilder() => APIAreaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is APIArea && id == other.id && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'APIArea')
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class APIAreaBuilder implements Builder<APIArea, APIAreaBuilder> {
  _$APIArea? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  APIAreaBuilder() {
    APIArea._defaults(this);
  }

  APIAreaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(APIArea other) {
    _$v = other as _$APIArea;
  }

  @override
  void update(void Function(APIAreaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  APIArea build() => _build();

  _$APIArea _build() {
    final _$result = _$v ??
        _$APIArea._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'APIArea', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'APIArea', 'name'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
