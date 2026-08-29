import 'package:flutter/material.dart';

import '../theme/appearance.dart';
import '../theme/appearance_scope.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppearanceScope.of(context);
    final appearance = scope.appearance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Look & feel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Color', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Pick a palette. Sprout green is the GardenSpacer look.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final palette in GardenPalette.values)
                _PaletteChoice(
                  palette: palette,
                  selected: appearance.palette == palette,
                  onTap: () => scope.onChanged(
                    appearance.copyWith(palette: palette),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Layout', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Cozy is cushiony, compact is tight, airy gives names more room.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<GardenLayout>(
            segments: [
              for (final layout in GardenLayout.values)
                ButtonSegment(
                  value: layout,
                  label: Text(layoutLabel(layout)),
                ),
            ],
            selected: {appearance.layout},
            onSelectionChanged: (selected) {
              scope.onChanged(
                appearance.copyWith(layout: selected.first),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaletteChoice extends StatelessWidget {
  final GardenPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteChoice({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = paletteSeed(palette);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          paletteLabel(palette),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
