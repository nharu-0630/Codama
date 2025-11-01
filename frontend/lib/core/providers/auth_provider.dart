import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 認証状態を管理するStateNotifier
///
/// ユーザーの認証状態（ログイン中かどうか）をアプリケーション全体で管理する。
/// 認証状態の変更は、UI全体に反映される。
class AuthStateNotifier extends StateNotifier<bool> {
  /// AuthStateNotifierのコンストラクタ
  ///
  /// 初期状態は未認証（false）として設定される。
  AuthStateNotifier() : super(false);

  /// 認証状態を更新する
  ///
  /// [isAuthenticated] 新しい認証状態（true: 認証済み, false: 未認証）
  void setAuthenticated(bool isAuthenticated) {
    state = isAuthenticated;
  }
}

/// 認証状態を提供するグローバルプロバイダー
///
/// アプリケーション全体でユーザーの認証状態を監視・取得するために使用される。
/// ウィジェットはこのプロバイダーを監視することで、認証状態の変更に応じて
/// UIを自動的に更新できる。
final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  return AuthStateNotifier();
});