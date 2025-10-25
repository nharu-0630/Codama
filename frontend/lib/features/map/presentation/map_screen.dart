import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/map_attribution.dart';

const _styleUrl = "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['STADIA_API_KEY'] ?? '';
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(35.4658, 139.6201), // 横浜駅
          zoom: 15,
          keepAlive: true,
          maxZoom: 18,
          minZoom: 10,
        ),
        nonRotatedChildren: [MapAttribution()],
        children: [
          TileLayer(
            urlTemplate: "$_styleUrl?api_key={api_key}",
            additionalOptions: {"api_key": apiKey},
            maxZoom: 20,
            maxNativeZoom: 20,
          ),
        ],
      ),
    );
  }
}