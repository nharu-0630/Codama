import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferencesインスタンスを提供するプロバイダー
///
/// アプリケーション全体で共有されるローカルストレージへのアクセスを提供する。
/// 認証トークンやユーザー設定の永続化に使用される。
///
/// 戻り値: SharedPreferencesのインスタンス
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});
