import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<User> signUp() async {
    return await _remoteDataSource.signup();
  }

  @override
  Future<User> signIn(String username, String password) async {
    return await _remoteDataSource.signIn(username, password);
  }

  @override
  Future<void> signOut() async {
    _remoteDataSource.clearTokens();
  }

  @override
  Future<User> getCurrentUser() async {
    final userId = _remoteDataSource.userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Try to refresh token to ensure valid session
    return await _remoteDataSource.refreshToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    return _remoteDataSource.isAuthenticated;
  }
}
