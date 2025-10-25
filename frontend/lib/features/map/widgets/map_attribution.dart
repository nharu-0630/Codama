import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(attributions: [
      TextSourceAttribution(
        "Stadia Maps",
        onTap: () => launchUrl(Uri.parse("https://stadiamaps.com/")),
        prependCopyright: true,
      ),
      TextSourceAttribution(
        "OpenMapTiles",
        onTap: () => launchUrl(Uri.parse("https://openmaptiles.org/")),
        prependCopyright: true,
      ),
      TextSourceAttribution(
        "OpenStreetMap",
        onTap: () => launchUrl(
          Uri.parse("https://www.openstreetmap.org/copyright"),
        ),
        prependCopyright: true,
      ),
    ]);
  }
}