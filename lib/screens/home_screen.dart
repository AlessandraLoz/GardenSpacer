import 'package:flutter/material.dart';

import '../data/bed_store.dart';
import '../logic/saved_bed_layout.dart';
import '../models/saved_bed.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('GardenSpacer'),
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
                        Text(
                          'Your beds will show up here',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a bed, give it a name, and tap it later to see how many plants fit.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _savedBeds.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final layout = layoutForSavedBed(_savedBeds[index]);
                      final count = layout.result?.count;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          title: Text(layout.bed.name),
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
