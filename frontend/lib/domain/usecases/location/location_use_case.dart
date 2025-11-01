import '../../entities/location_data.dart';
import '../../repositories/location_repository.dart';

abstract class LocationUseCase {
  Future<LocationData?> getCurrentLocation(double lat, double lon);
}

class LocationUseCaseImpl implements LocationUseCase {
  final LocationRepository _repository;

  LocationUseCaseImpl(this._repository);

  @override
  Future<LocationData?> getCurrentLocation(double lat, double lon) async {
    return await _repository.getCurrentLocation(lat, lon);
  }
}