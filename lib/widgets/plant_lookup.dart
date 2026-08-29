import 'package:flutter/material.dart';

import '../logic/packet_parser.dart';
import '../logic/packet_web_search.dart';
import '../logic/saved_bed_layout.dart';
import '../models/plant.dart';

int plantMatchScore(Plant plant, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return 1;
  }
  final name = plant.name.toLowerCase();
  final display = plant.displayName.toLowerCase();
  final brand = (plant.brand ?? '').toLowerCase();
  if (display == q || name == q) {
    return 100;
  }
  if (display.startsWith(q) || name.startsWith(q)) {
    return 80;
  }
  if (brand.isNotEmpty && brand == q) {
    return 70;
  }
  if (plantMatchesQuery(plant, q)) {
    return 40;
  }
  return 0;
}

bool plantMatchesQuery(Plant plant, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  final haystack = [
    plant.name,
    plant.displayName,
    plant.category,
    plant.brand ?? '',
    plant.packetExtract ?? '',
  ].join(' ').toLowerCase();
  return haystack.contains(q);
}

List<Plant> rankCatalogPlants(String query) {
  final scored = [
    for (final plant in catalogPlants)
      (plant: plant, score: plantMatchScore(plant, query)),
  ].where((item) => item.score > 0).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return [for (final item in scored) item.plant];
}

Future<Plant?> showPlantLookup(
  BuildContext context, {
  Plant? selected,
}) {
  return showModalBottomSheet<Plant>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _PlantLookupSheet(selected: selected);
    },
  );
}

class _PlantLookupSheet extends StatefulWidget {
  final Plant? selected;

  const _PlantLookupSheet({this.selected});

  @override
  State<_PlantLookupSheet> createState() => _PlantLookupSheetState();
}

class _PlantLookupSheetState extends State<_PlantLookupSheet> {
  final _queryController = TextEditingController();
  String _query = '';
  List<WebPacketHit> _webHits = [];
  bool _webLoading = false;
  String? _webError;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _searchWeb() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _webError = 'Type a packet or plant name, then search the web.';
      });
      return;
    }
    setState(() {
      _query = query;
      _webLoading = true;
      _webError = null;
    });
    try {
      final hits = await searchSeedPacketsOnline(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _webHits = hits;
        _webLoading = false;
        if (hits.isEmpty) {
          _webError = 'No online packets found. Try the exact packet name.';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _webLoading = false;
        _webError = 'Could not reach the internet. Try again.';
      });
    }
  }

  Plant? _plantFromHit(WebPacketHit hit) {
    final name = packetNameFromTitle(hit.title);
    return parseSeedPacketText(
      '${hit.title}. ${hit.snippet}',
      name: name.isEmpty ? hit.title : name,
      brand: hit.brand,
    )?.plant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = rankCatalogPlants(_query);
    final height = MediaQuery.sizeOf(context).height * 0.8;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Packet or plant name',
                hintText: 'Exact name, or tomato, Burpee…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              onSubmitted: (_) => _searchWeb(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilledButton.tonal(
                  onPressed: _webLoading ? null : _searchWeb,
                  child: const Text('Search the web'),
                ),
                const SizedBox(width: 12),
                if (_webLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (local.isNotEmpty) ...[
                  ListTile(
                    dense: true,
                    title: Text(
                      _query.trim().isEmpty
                          ? 'In this app'
                          : 'Best matches in this app',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  for (final plant in local.take(8))
                    ListTile(
                      selected:
                          plant.displayName == widget.selected?.displayName,
                      title: Text(plant.displayName),
                      subtitle: Text(
                        [
                          plant.category,
                          if (plant.packetExtract != null) plant.packetExtract!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(plant),
                    ),
                ],
                if (_webHits.isNotEmpty) ...[
                  ListTile(
                    dense: true,
                    title: Text(
                      'Recommended from the web',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: const Text(
                      'Spacing is read from the listing when possible.',
                    ),
                  ),
                  for (final hit in _webHits)
                    Builder(
                      builder: (context) {
                        final plant = _plantFromHit(hit);
                        return ListTile(
                          enabled: plant != null,
                          title: Text(hit.title),
                          subtitle: Text(
                            plant == null
                                ? 'Could not read spacing from this listing'
                                : [
                                    if (hit.brand != null) hit.brand!,
                                    plant.packetExtract ?? '',
                                  ].where((part) => part.isNotEmpty).join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: plant == null
                              ? null
                              : () => Navigator.of(context).pop(plant),
                        );
                      },
                    ),
                ],
                if (_webError != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _webError!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                if (local.isEmpty && _webHits.isEmpty && !_webLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Type an exact packet name, or search the web for recommended packets.',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
