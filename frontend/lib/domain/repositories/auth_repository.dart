import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signUp();
  Future<User> signIn(String username, String password);
  Future<void> signOut();
  Future<User> getCurrentUser();
  Future<bool> isAuthenticated();
}
