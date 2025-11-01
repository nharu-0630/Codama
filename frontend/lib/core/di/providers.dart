import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:codama/features/location/services/cell_tracking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final openApiFactoryProvider = Provider<OpenApiFactory>((ref) {
  return OpenApiFactory();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final openApiFactory = ref.read(openApiFactoryProvider);
  final sharedPreferences = ref.read(sharedPreferencesProvider).value!;
  final logger = ref.read(loggerServiceProvider);

  return ApiService(
    openApiFactory: openApiFactory,
    sharedPreferences: sharedPreferences,
    logger: logger,
    baseUrl: 'http://localhost:8000',
  );
});

final cellTrackingServiceProvider = Provider<CellTrackingService>((ref) {
  final apiService = ref.read(apiServiceProvider);

  return CellTrackingService(apiService: apiService);
});
