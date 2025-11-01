// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_cell.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$APICell extends APICell {
  @override
  final String geoHash;
  @override
  final int id;
  @override
  final BuiltList<JsonObject?> location;

  factory _$APICell([void Function(APICellBuilder)? updates]) =>
      (APICellBuilder()..update(updates))._build();

  _$APICell._({required this.geoHash, required this.id, required this.location})
      : super._();
  @override
  APICell rebuild(void Function(APICellBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  APICellBuilder toBuilder() => APICellBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is APICell &&
        geoHash == other.geoHash &&
        id == other.id &&
        location == other.location;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, geoHash.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'APICell')
          ..add('geoHash', geoHash)
          ..add('id', id)
          ..add('location', location))
        .toString();
  }
}

class APICellBuilder implements Builder<APICell, APICellBuilder> {
  _$APICell? _$v;

  String? _geoHash;
  String? get geoHash => _$this._geoHash;
  set geoHash(String? geoHash) => _$this._geoHash = geoHash;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  ListBuilder<JsonObject?>? _location;
  ListBuilder<JsonObject?> get location =>
      _$this._location ??= ListBuilder<JsonObject?>();
  set location(ListBuilder<JsonObject?>? location) =>
      _$this._location = location;

  APICellBuilder() {
    APICell._defaults(this);
  }

  APICellBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _geoHash = $v.geoHash;
      _id = $v.id;
      _location = $v.location.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(APICell other) {
    _$v = other as _$APICell;
  }

  @override
  void update(void Function(APICellBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  APICell build() => _build();

  _$APICell _build() {
    _$APICell _$result;
    try {
      _$result = _$v ??
          _$APICell._(
            geoHash: BuiltValueNullFieldError.checkNotNull(
                geoHash, r'APICell', 'geoHash'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'APICell', 'id'),
            location: location.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'location';
        location.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'APICell', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
