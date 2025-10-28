import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../data/datasources/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> signUp() async {
    try {
      return await _remoteDataSource.signup();
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  @override
  Future<User> signIn(String username, String password) async {
    try {
      return await _remoteDataSource.signIn(username, password);
    } catch (e) {
      throw Exception('Signin failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _remoteDataSource.clearTokens();
  }

  @override
  Future<User> getCurrentUser() async {
    if (_remoteDataSource.isAuthenticated) {
      return User(
        id: _remoteDataSource.userId ?? '',
        createdAt: DateTime.now(),
      );
    } else {
      throw Exception('No authenticated user');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _remoteDataSource.isAuthenticated;
  }
}