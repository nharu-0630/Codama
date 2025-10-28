import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/map/presentation/map_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        textTheme: GoogleFonts.zenMaruGothicTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}
