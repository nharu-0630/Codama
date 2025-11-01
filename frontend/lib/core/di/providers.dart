import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/auth_remote_data_source.dart';
import '../../data/datasources/remote/location_remote_data_source.dart';
import '../../data/datasources/remote/post_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/auth/auth_use_case.dart';
import '../../domain/usecases/location/location_use_case.dart';
import '../../domain/usecases/post/post_use_case.dart';
import '../../features/location/services/cell_tracking_service.dart';
import '../logging/logger_service.dart';

// Core dependencies
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.read(dioProvider);
  return ApiClient(dio);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final sharedPreferences = ref.read(sharedPreferencesProvider).value!;
  final logger = ref.read(loggerServiceProvider);

  return AuthRemoteDataSourceImpl(
    apiClient: apiClient,
    sharedPreferences: sharedPreferences,
    logger: logger,
  );
});

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((
  ref,
) {
  final apiClient = ref.read(apiClientProvider);
  final logger = ref.read(loggerServiceProvider);

  return LocationRemoteDataSourceImpl(apiClient: apiClient, logger: logger);
});

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final logger = ref.read(loggerServiceProvider);

  return PostRemoteDataSourceImpl(apiClient: apiClient, logger: logger);
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final remoteDataSource = ref.read(locationRemoteDataSourceProvider);
  return LocationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final remoteDataSource = ref.read(postRemoteDataSourceProvider);
  return PostRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Cases
final authUseCaseProvider = Provider<AuthUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthUseCaseImpl(repository);
});

final locationUseCaseProvider = Provider<LocationUseCase>((ref) {
  final repository = ref.read(locationRepositoryProvider);
  return LocationUseCaseImpl(repository);
});

final postUseCaseProvider = Provider<PostUseCase>((ref) {
  final repository = ref.read(postRepositoryProvider);
  return PostUseCaseImpl(repository);
});

// Cell Tracking Service Provider
final cellTrackingServiceProvider = Provider<CellTrackingService>((ref) {
  final authUseCase = ref.read(authUseCaseProvider);
  final locationUseCase = ref.read(locationUseCaseProvider);
  final postUseCase = ref.read(postUseCaseProvider);

  return CellTrackingService(
    authUseCase: authUseCase,
    locationUseCase: locationUseCase,
    postUseCase: postUseCase,
  );
});
