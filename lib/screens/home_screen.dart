import 'package:flutter/material.dart';

import '../data/bed_store.dart';
import '../logic/garden_list.dart';
import '../logic/saved_bed_layout.dart';
import '../models/saved_bed.dart';
import '../theme/appearance.dart';
import '../theme/appearance_scope.dart';
import '../theme/garden_icons.dart';
import 'appearance_screen.dart';
import 'bed_detail_screen.dart';
import 'bed_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = BedStore();
  List<SavedBed> _savedBeds = [];
  final _selectedNames = <String>{};
  bool _loading = true;
  bool _selecting = false;
  GardenKindFilter _filter = GardenKindFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final beds = await _store.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedBeds = beds;
      _loading = false;
      _selectedNames.removeWhere(
        (name) => beds.every((bed) => bed.name != name),
      );
      if (_selectedNames.isEmpty) {
        _selecting = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selecting = false;
      _selectedNames.clear();
    });
  }

  void _toggleSelected(SavedBed bed) {
    setState(() {
      _selecting = true;
      if (!_selectedNames.add(bed.name)) {
        _selectedNames.remove(bed.name);
      }
      if (_selectedNames.isEmpty) {
        _selecting = false;
      }
    });
  }

  Future<void> _openEditor({SavedBed? existing, SavedBed? draft}) async {
    final saved = await Navigator.of(context).push<SavedBed>(
      MaterialPageRoute(
        builder: (context) => BedEditorScreen(
          existing: existing,
          draft: draft,
        ),
      ),
    );
    if (saved != null) {
      await _reload();
      if (!mounted) {
        return;
      }
      await _openDetail(saved);
    }
  }

  Future<void> _combineSelected() async {
    final selected = [
      for (final bed in _savedBeds)
        if (_selectedNames.contains(bed.name)) bed,
    ];
    if (selected.length < 2) {
      return;
    }
    _clearSelection();
    await _openEditor(draft: draftMasterFromBeds(selected));
  }

  Future<void> _openDetail(SavedBed bed) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (context) => BedDetailScreen(bed: bed),
      ),
    );
    if (result is SavedBed) {
      await _reload();
      if (!mounted) {
        return;
      }
      await _openDetail(result);
      return;
    }
    await _reload();
  }

  List<Object> _listRows() {
    final rows = <Object>[];
    for (final section in gardenListSections(_savedBeds, _filter)) {
      rows.add(section.title);
      rows.addAll(section.beds);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = AppearanceScope.of(context).appearance;
    final cozy = appearance.layout != GardenLayout.compact;
    final canCombine = _selectedNames.length >= 2;
    final rows = _listRows();
    final hasMasters = _savedBeds.any((bed) => bed.isMaster);
    final hasSingles = _savedBeds.any((bed) => !bed.isMaster);

    return Scaffold(
      appBar: AppBar(
        leading: _selecting
            ? IconButton(
                tooltip: 'Cancel',
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _selecting ? '${_selectedNames.length} selected' : 'GardenSpacer',
        ),
        actions: [
          if (_selecting)
            TextButton(
              onPressed: canCombine ? _combineSelected : null,
              child: const Text('Combine'),
            )
          else ...[
            if (_savedBeds.length >= 2)
              IconButton(
                tooltip: 'Combine gardens',
                onPressed: () {
                  setState(() {
                    _selecting = true;
                  });
                },
                icon: const Icon(Icons.merge_outlined),
              ),
            IconButton(
              tooltip: 'Look & feel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.palette_outlined),
            ),
          ],
        ],
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: _openEditor,
              icon: const Icon(Icons.add),
              label: const Text('New bed'),
            ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _savedBeds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 88,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your garden starts here',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name a bed, add plants and spacing, and it will live on this list.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              selected: _filter == GardenKindFilter.all,
                              showCheckmark: false,
                              label: const Text('All'),
                              onSelected: (_) {
                                setState(() {
                                  _filter = GardenKindFilter.all;
                                });
                              },
                            ),
                            FilterChip(
                              selected: _filter == GardenKindFilter.single,
                              showCheckmark: false,
                              label: const Text('Single plant'),
                              onSelected: (_) {
                                setState(() {
                                  _filter = GardenKindFilter.single;
                                });
                              },
                            ),
                            FilterChip(
                              selected: _filter == GardenKindFilter.master,
                              showCheckmark: false,
                              label: const Text('Master'),
                              onSelected: (_) {
                                setState(() {
                                  _filter = GardenKindFilter.master;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_selecting)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Text(
                            'Select two or more gardens, then Combine to share one master bed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      Expanded(
                        child: rows.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _filter == GardenKindFilter.master
                                      ? hasSingles
                                          ? 'No master beds yet. Combine gardens or add more than one plant to a bed.'
                                          : 'No master beds yet.'
                                      : hasMasters
                                          ? 'No single-plant beds in this list.'
                                          : 'No gardens in this list.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.separated(
                                padding: layoutPadding(appearance.layout),
                                itemCount: rows.length,
                                separatorBuilder: (context, index) {
                                  final next = index + 1 < rows.length
                                      ? rows[index + 1]
                                      : null;
                                  if (rows[index] is String || next is String) {
                                    return const SizedBox(height: 8);
                                  }
                                  return SizedBox(
                                    height: appearance.layout ==
                                            GardenLayout.airy
                                        ? 16
                                        : 10,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  if (row is String) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        row,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    );
                                  }
                                  final bed = row as SavedBed;
                                  final layout = layoutForSavedBed(bed);
                                  final count = layout.result?.count;
                                  final selected = _selectedNames.contains(
                                    layout.bed.name,
                                  );
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    color: selected
                                        ? theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.45)
                                        : null,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: cozy ? 20 : 12,
                                        vertical:
                                            appearance.layout == GardenLayout.airy
                                                ? 16
                                                : cozy
                                                    ? 10
                                                    : 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        child: Icon(
                                          gardenIconData(layout.bed.icon),
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      title: Text(
                                        layout.bed.name,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      subtitle: Text(
                                        [
                                          layout.plantLabel,
                                          layout.sizeLabel,
                                          if (count != null)
                                            count == 1
                                                ? '1 plant fits'
                                                : '$count plants fit',
                                        ].join('\n'),
                                      ),
                                      isThreeLine: true,
                                      trailing: _selecting
                                          ? Icon(
                                              selected
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color: theme.colorScheme.primary,
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  bed.isMaster
                                                      ? 'Master'
                                                      : 'Single',
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                const Icon(Icons.chevron_right),
                                              ],
                                            ),
                                      onTap: () {
                                        if (_selecting) {
                                          _toggleSelected(layout.bed);
                                        } else {
                                          _openDetail(layout.bed);
                                        }
                                      },
                                      onLongPress: () =>
                                          _toggleSelected(layout.bed),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
