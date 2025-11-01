// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_prompt_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePromptResponse extends UpdatePromptResponse {
  @override
  final bool success;

  factory _$UpdatePromptResponse(
          [void Function(UpdatePromptResponseBuilder)? updates]) =>
      (UpdatePromptResponseBuilder()..update(updates))._build();

  _$UpdatePromptResponse._({required this.success}) : super._();
  @override
  UpdatePromptResponse rebuild(
          void Function(UpdatePromptResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePromptResponseBuilder toBuilder() =>
      UpdatePromptResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePromptResponse && success == other.success;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, success.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePromptResponse')
          ..add('success', success))
        .toString();
  }
}

class UpdatePromptResponseBuilder
    implements Builder<UpdatePromptResponse, UpdatePromptResponseBuilder> {
  _$UpdatePromptResponse? _$v;

  bool? _success;
  bool? get success => _$this._success;
  set success(bool? success) => _$this._success = success;

  UpdatePromptResponseBuilder() {
    UpdatePromptResponse._defaults(this);
  }

  UpdatePromptResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _success = $v.success;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePromptResponse other) {
    _$v = other as _$UpdatePromptResponse;
  }

  @override
  void update(void Function(UpdatePromptResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePromptResponse build() => _build();

  _$UpdatePromptResponse _build() {
    final _$result = _$v ??
        _$UpdatePromptResponse._(
          success: BuiltValueNullFieldError.checkNotNull(
              success, r'UpdatePromptResponse', 'success'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
