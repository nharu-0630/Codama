import '../entities/location_data.dart';

abstract class LocationRepository {
  Future<LocationData?> getCurrentLocation(double lat, double lon);
}