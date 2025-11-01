// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SignupResponse extends SignupResponse {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final String userId;

  factory _$SignupResponse([void Function(SignupResponseBuilder)? updates]) =>
      (SignupResponseBuilder()..update(updates))._build();

  _$SignupResponse._(
      {required this.accessToken,
      required this.refreshToken,
      required this.userId})
      : super._();
  @override
  SignupResponse rebuild(void Function(SignupResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SignupResponseBuilder toBuilder() => SignupResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SignupResponse &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SignupResponse')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('userId', userId))
        .toString();
  }
}

class SignupResponseBuilder
    implements Builder<SignupResponse, SignupResponseBuilder> {
  _$SignupResponse? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  SignupResponseBuilder() {
    SignupResponse._defaults(this);
  }

  SignupResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SignupResponse other) {
    _$v = other as _$SignupResponse;
  }

  @override
  void update(void Function(SignupResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SignupResponse build() => _build();

  _$SignupResponse _build() {
    final _$result = _$v ??
        _$SignupResponse._(
          accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken, r'SignupResponse', 'accessToken'),
          refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken, r'SignupResponse', 'refreshToken'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'SignupResponse', 'userId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
