import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

abstract class AuthUseCase {
  Future<User> signUp();
  Future<User> signIn(String username, String password);
  Future<void> signOut();
  Future<User> getCurrentUser();
  Future<bool> isAuthenticated();
}

class AuthUseCaseImpl implements AuthUseCase {
  final AuthRepository _repository;

  AuthUseCaseImpl(this._repository);

  @override
  Future<User> signUp() async {
    return await _repository.signUp();
  }

  @override
  Future<User> signIn(String username, String password) async {
    return await _repository.signIn(username, password);
  }

  @override
  Future<void> signOut() async {
    await _repository.signOut();
  }

  @override
  Future<User> getCurrentUser() async {
    return await _repository.getCurrentUser();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _repository.isAuthenticated();
  }
}