import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const GardenSpacerApp());
}

class GardenSpacerApp extends StatelessWidget {
  const GardenSpacerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GardenSpacer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6B4F)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
