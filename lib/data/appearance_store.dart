import 'package:shared_preferences/shared_preferences.dart';

import '../theme/appearance.dart';

class AppearanceStore {
  static const _paletteKey = 'appearance_palette';
  static const _layoutKey = 'appearance_layout';

  Future<Appearance> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_paletteKey);
    final layoutName = prefs.getString(_layoutKey);
    return Appearance(
      palette: GardenPalette.values.firstWhere(
        (value) => value.name == paletteName,
        orElse: () => GardenPalette.sprout,
      ),
      layout: GardenLayout.values.firstWhere(
        (value) => value.name == layoutName,
        orElse: () => GardenLayout.cozy,
      ),
    );
  }

  Future<void> save(Appearance appearance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, appearance.palette.name);
    await prefs.setString(_layoutKey, appearance.layout.name);
  }
}
