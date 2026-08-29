import 'package:flutter/material.dart';

import '../data/bed_store.dart';
import '../logic/saved_bed_layout.dart';
import '../models/saved_bed.dart';
import '../theme/appearance.dart';
import '../theme/appearance_scope.dart';
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
  bool _loading = true;

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
    });
  }

  Future<void> _openEditor({SavedBed? existing}) async {
    final saved = await Navigator.of(context).push<SavedBed>(
      MaterialPageRoute(
        builder: (context) => BedEditorScreen(existing: existing),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = AppearanceScope.of(context).appearance;
    final cozy = appearance.layout != GardenLayout.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GardenSpacer'),
        actions: [
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
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                          'Name a bed, pick a packet, and it will live on this list.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: layoutPadding(appearance.layout),
                    itemCount: _savedBeds.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: appearance.layout == GardenLayout.airy ? 16 : 10,
                    ),
                    itemBuilder: (context, index) {
                      final layout = layoutForSavedBed(_savedBeds[index]);
                      final count = layout.result?.count;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: cozy ? 20 : 12,
                            vertical: appearance.layout == GardenLayout.airy
                                ? 16
                                : cozy
                                    ? 10
                                    : 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.local_florist_rounded,
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
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openDetail(layout.bed),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
