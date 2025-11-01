// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CurrentResponse extends CurrentResponse {
  @override
  final APIArea area;
  @override
  final APICell cell;

  factory _$CurrentResponse([void Function(CurrentResponseBuilder)? updates]) =>
      (CurrentResponseBuilder()..update(updates))._build();

  _$CurrentResponse._({required this.area, required this.cell}) : super._();
  @override
  CurrentResponse rebuild(void Function(CurrentResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CurrentResponseBuilder toBuilder() => CurrentResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CurrentResponse && area == other.area && cell == other.cell;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, area.hashCode);
    _$hash = $jc(_$hash, cell.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CurrentResponse')
          ..add('area', area)
          ..add('cell', cell))
        .toString();
  }
}

class CurrentResponseBuilder
    implements Builder<CurrentResponse, CurrentResponseBuilder> {
  _$CurrentResponse? _$v;

  APIAreaBuilder? _area;
  APIAreaBuilder get area => _$this._area ??= APIAreaBuilder();
  set area(APIAreaBuilder? area) => _$this._area = area;

  APICellBuilder? _cell;
  APICellBuilder get cell => _$this._cell ??= APICellBuilder();
  set cell(APICellBuilder? cell) => _$this._cell = cell;

  CurrentResponseBuilder() {
    CurrentResponse._defaults(this);
  }

  CurrentResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _area = $v.area.toBuilder();
      _cell = $v.cell.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CurrentResponse other) {
    _$v = other as _$CurrentResponse;
  }

  @override
  void update(void Function(CurrentResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CurrentResponse build() => _build();

  _$CurrentResponse _build() {
    _$CurrentResponse _$result;
    try {
      _$result = _$v ??
          _$CurrentResponse._(
            area: area.build(),
            cell: cell.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'area';
        area.build();
        _$failedField = 'cell';
        cell.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CurrentResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
