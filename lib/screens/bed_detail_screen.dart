import 'package:flutter/material.dart';

import '../data/bed_store.dart';
import '../logic/saved_bed_layout.dart';
import '../models/saved_bed.dart';
import '../theme/garden_icons.dart';
import '../widgets/bed_sketch.dart';
import 'bed_editor_screen.dart';

class BedDetailScreen extends StatelessWidget {
  final SavedBed bed;

  const BedDetailScreen({super.key, required this.bed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = layoutForSavedBed(bed);
    final count = layout.result?.count;
    final mixed = layout.plantings.length > 1;
    final colors = gardenCropColors(theme.colorScheme);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(gardenIconData(bed.icon)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bed.name,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.of(context).push<SavedBed>(
                MaterialPageRoute(
                  builder: (context) => BedEditorScreen(existing: bed),
                ),
              );
              if (updated != null && context.mounted) {
                Navigator.of(context).pop(updated);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              await BedStore().delete(bed.name);
              if (context.mounted) {
                Navigator.of(context).pop('deleted');
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              bed.isMaster ? 'Master bed' : 'Single-plant bed',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              layout.plantLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              layout.sizeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (mixed) ...[
              const SizedBox(height: 8),
              Text(
                'Each labeled rectangle is a sub-bed at its placed size.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (count != null) ...[
              Text(
                '$count',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count == 1 ? 'plant fits' : 'plants fit',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (!mixed &&
                  layout.result?.rows != null &&
                  layout.result?.perRow != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${layout.result!.rows} rows × ${layout.result!.perRow} per row',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (mixed) ...[
                const SizedBox(height: 16),
                for (var i = 0; i < layout.plantings.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colors[i % colors.length],
                    ),
                    title: Text(layout.plantings[i].label),
                    subtitle: Text(
                      '${layout.plantings[i].result?.rows ?? 0} rows × ${layout.plantings[i].result?.perRow ?? 0} per row',
                    ),
                    trailing: Text(
                      '${layout.plantings[i].result?.count ?? 0}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              BedSketch(
                lengthIn: layout.lengthIn,
                widthIn: layout.widthIn,
                crops: [
                  for (var i = 0; i < layout.plantings.length; i++)
                    SketchCrop(
                      color: colors[i % colors.length],
                      plantCount: layout.plantings[i].result?.count ?? 0,
                      rows: layout.plantings[i].result?.rows ?? 1,
                      perRow: layout.plantings[i].result?.perRow ??
                          (layout.plantings[i].result?.count ?? 1).clamp(1, 80),
                      xIn: layout.plantings[i].rect.x,
                      yIn: layout.plantings[i].rect.y,
                      lengthIn: layout.plantings[i].rect.length,
                      widthIn: layout.plantings[i].rect.width,
                      label: layout.plantings[i].label,
                    ),
                ],
              ),
            ] else
              Text(
                'Could not calculate this bed. Edit it and check the plant spacing.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
