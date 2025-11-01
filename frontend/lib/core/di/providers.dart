import 'package:codama/core/api/openapi_factory.dart';
import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:codama/core/services/logger_service.dart';
import 'package:codama/features/location/services/cell_tracking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  final sharedPreferences = await ref.read(sharedPreferencesProvider.future);
  final logger = ref.read(loggerServiceProvider);

  final apiService = ApiService(
    openApiFactory: OpenApiFactory(),
    sharedPreferences: sharedPreferences,
    logger: logger,
    baseUrl: Config.baseUrl,
    ref: ref,
  );

  return apiService;
});

final cellTrackingServiceProvider = FutureProvider<CellTrackingService>((
  ref,
) async {
  final apiService = await ref.read(apiServiceProvider.future);

  return CellTrackingService(apiService: apiService);
});
