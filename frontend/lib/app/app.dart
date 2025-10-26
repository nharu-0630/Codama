import 'package:flutter/material.dart';

import '../features/map/presentation/map_screen.dart';

class KodamaMapApp extends StatelessWidget {
  const KodamaMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kodama Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
