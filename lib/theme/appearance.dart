import 'package:flutter/material.dart';

enum GardenPalette {
  sprout,
  moss,
  tomato,
  sunflower,
  sky,
  lilac,
}

enum GardenLayout {
  cozy,
  compact,
  airy,
}

class Appearance {
  final GardenPalette palette;
  final GardenLayout layout;

  const Appearance({
    this.palette = GardenPalette.sprout,
    this.layout = GardenLayout.cozy,
  });

  Appearance copyWith({
    GardenPalette? palette,
    GardenLayout? layout,
  }) {
    return Appearance(
      palette: palette ?? this.palette,
      layout: layout ?? this.layout,
    );
  }
}

Color paletteSeed(GardenPalette palette) {
  switch (palette) {
    case GardenPalette.sprout:
      return const Color(0xFF1F7A4C);
    case GardenPalette.moss:
      return const Color(0xFF4A7C59);
    case GardenPalette.tomato:
      return const Color(0xFFC45C4A);
    case GardenPalette.sunflower:
      return const Color(0xFFD4920A);
    case GardenPalette.sky:
      return const Color(0xFF3D8EA8);
    case GardenPalette.lilac:
      return const Color(0xFF7A6BA8);
  }
}

String paletteLabel(GardenPalette palette) {
  switch (palette) {
    case GardenPalette.sprout:
      return 'Sprout green';
    case GardenPalette.moss:
      return 'Moss';
    case GardenPalette.tomato:
      return 'Tomato';
    case GardenPalette.sunflower:
      return 'Sunflower';
    case GardenPalette.sky:
      return 'Sky';
    case GardenPalette.lilac:
      return 'Lilac';
  }
}

String layoutLabel(GardenLayout layout) {
  switch (layout) {
    case GardenLayout.cozy:
      return 'Cozy';
    case GardenLayout.compact:
      return 'Compact';
    case GardenLayout.airy:
      return 'Airy';
  }
}

double layoutRadius(GardenLayout layout) {
  switch (layout) {
    case GardenLayout.cozy:
      return 28;
    case GardenLayout.compact:
      return 12;
    case GardenLayout.airy:
      return 32;
  }
}

EdgeInsets layoutPadding(GardenLayout layout) {
  switch (layout) {
    case GardenLayout.cozy:
      return const EdgeInsets.fromLTRB(16, 16, 16, 96);
    case GardenLayout.compact:
      return const EdgeInsets.fromLTRB(12, 8, 12, 88);
    case GardenLayout.airy:
      return const EdgeInsets.fromLTRB(20, 24, 20, 104);
  }
}
