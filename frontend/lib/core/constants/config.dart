import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Config {
  Config._();

  static const String userAgent = 'CodamaApp';
  static const Duration timeout = Duration(seconds: 5);

  static const LatLng defaultLocation = LatLng(35.658871, 139.701960);
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
  );

  static const double defaultZoom = 17.0;
  static const double compassZoom = 17.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 16.0;

  static const String styleUrl =
      'https://tiles.stadiamaps.com/tiles/stamen_watercolor/{z}/{x}/{y}.jpg';
}
