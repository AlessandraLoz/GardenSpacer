import 'package:flutter/material.dart';

const gardenIconIds = [
  'eco',
  'florist',
  'grass',
  'spa',
  'yard',
  'forest',
  'sunny',
  'water',
  'vintage',
  'compost',
  'bug',
  'bowl',
];

IconData gardenIconData(String? id) {
  switch (id) {
    case 'florist':
      return Icons.local_florist_rounded;
    case 'grass':
      return Icons.grass;
    case 'spa':
      return Icons.spa_rounded;
    case 'yard':
      return Icons.yard_rounded;
    case 'forest':
      return Icons.forest;
    case 'sunny':
      return Icons.wb_sunny_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'vintage':
      return Icons.filter_vintage_rounded;
    case 'compost':
      return Icons.compost;
    case 'bug':
      return Icons.emoji_nature_rounded;
    case 'bowl':
      return Icons.rice_bowl_outlined;
    case 'eco':
    default:
      return Icons.eco_rounded;
  }
}
