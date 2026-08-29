import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appearance.dart';

ThemeData gardenTheme(Appearance appearance) {
  final seed = paletteSeed(appearance.palette);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final radius = layoutRadius(appearance.layout);
  final display = GoogleFonts.fredoka(
    fontWeight: FontWeight.w600,
    color: scheme.onSurface,
  );
  final body = GoogleFonts.nunito(
    color: scheme.onSurface,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: TextTheme(
      displayLarge: display.copyWith(fontSize: 56, fontWeight: FontWeight.w700),
      headlineMedium: display.copyWith(fontSize: 28),
      titleLarge: display.copyWith(fontSize: 22),
      titleMedium: display.copyWith(fontSize: 18),
      bodyLarge: body.copyWith(fontSize: 16, height: 1.35),
      bodyMedium: body.copyWith(fontSize: 14, height: 1.35),
      labelLarge: body.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      titleTextStyle: display.copyWith(
        fontSize: 22,
        color: scheme.onPrimaryContainer,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: appearance.layout == GardenLayout.compact ? 0 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      extendedTextStyle: display.copyWith(fontSize: 16, color: scheme.onPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius * 0.7),
        ),
        textStyle: display.copyWith(fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius * 0.55),
      ),
    ),
  );
}
