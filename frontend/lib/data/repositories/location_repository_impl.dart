import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/remote/location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;

  LocationRepositoryImpl({required LocationRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<LocationData?> getCurrentLocation(double lat, double lon) async {
    return await _remoteDataSource.getCurrentLocation(lat, lon);
  }
}
