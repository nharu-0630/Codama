import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationConfig {
  LocationConfig._();

  static const LatLng defaultLocation = LatLng(35.658871, 139.701960);
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 1,
  );

  static const double defaultZoom = 17.0;
  static const double compassZoom = 17.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 16.0;
}
