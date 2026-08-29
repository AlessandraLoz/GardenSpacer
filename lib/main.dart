import 'package:flutter/material.dart';

import 'data/appearance_store.dart';
import 'screens/home_screen.dart';
import 'theme/appearance.dart';
import 'theme/appearance_scope.dart';
import 'theme/garden_theme.dart';

void main() {
  runApp(const GardenSpacerApp());
}

class GardenSpacerApp extends StatefulWidget {
  const GardenSpacerApp({super.key});

  @override
  State<GardenSpacerApp> createState() => _GardenSpacerAppState();
}

class _GardenSpacerAppState extends State<GardenSpacerApp> {
  final _store = AppearanceStore();
  Appearance _appearance = const Appearance();

  @override
  void initState() {
    super.initState();
    _store.load().then((value) {
      if (mounted) {
        setState(() {
          _appearance = value;
        });
      }
    });
  }

  Future<void> _onAppearanceChanged(Appearance appearance) async {
    setState(() {
      _appearance = appearance;
    });
    await _store.save(appearance);
  }

  @override
  Widget build(BuildContext context) {
    return AppearanceScope(
      appearance: _appearance,
      onChanged: _onAppearanceChanged,
      child: MaterialApp(
        title: 'GardenSpacer',
        theme: gardenTheme(_appearance),
        home: const HomeScreen(),
      ),
    );
  }
}
