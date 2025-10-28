import '../../../../core/logging/logger_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../domain/entities/location_data.dart' as domain;

abstract class LocationRemoteDataSource {
  Future<domain.LocationData?> getCurrentLocation(double lat, double lon);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final ApiClient _apiClient;
  final LoggerService _logger;

  LocationRemoteDataSourceImpl({
    required ApiClient apiClient,
    required LoggerService logger,
  }) : _apiClient = apiClient,
       _logger = logger;

  @override
  Future<domain.LocationData?> getCurrentLocation(
    double lat,
    double lon,
  ) async {
    try {
      final response = await _apiClient.getCurrentLocation(lat, lon);
      return domain.LocationData(
        area: domain.Area(
          id: 0, // API response doesn't include area id
          name: response.area.name,
        ),
        cell: domain.Cell(
          id: response.cell.id,
          geoHash: '', // API response doesn't include geoHash
          location: [], // API response doesn't include location
        ),
      );
    } catch (e) {
      _logger.e('Failed to get current location: $e');
      return null;
    }
  }
}
