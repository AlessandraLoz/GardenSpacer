import 'package:flutter/material.dart';

import '../data/bed_store.dart';
import '../logic/saved_bed_layout.dart';
import '../models/saved_bed.dart';
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
    final rows = layout.result?.rows;
    final perRow = layout.result?.perRow;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bed.name,
          style: theme.textTheme.titleLarge,
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
              if (rows != null && perRow != null) ...[
                const SizedBox(height: 8),
                Text(
                  '$rows rows × $perRow per row',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BedSketch(
                lengthIn: layout.lengthIn,
                widthIn: layout.widthIn,
                plantCount: count,
                rows: rows,
                perRow: perRow,
              ),
            ] else
              Text(
                'Could not calculate this bed. Edit it and check the plant or packet text.',
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
