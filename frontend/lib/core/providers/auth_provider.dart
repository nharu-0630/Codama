import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthStateNotifier extends StateNotifier<bool> {
  AuthStateNotifier() : super(false);

  void setAuthenticated(bool isAuthenticated) {
    state = isAuthenticated;
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  return AuthStateNotifier();
});