import 'package:codama/core/services/api_service.dart';
import 'package:codama/features/location/services/cell_tracking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cellTrackingServiceProvider = Provider<CellTrackingService>((ref) {
  final apiService = ref.read(apiServiceProvider);

  return CellTrackingService(apiService: apiService);
});
