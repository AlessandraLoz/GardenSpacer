import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/packet_web_search.dart';
import '../logic/plant_search.dart';
import '../logic/saved_bed_layout.dart';
import '../logic/unit_conversion.dart';
import '../models/plant.dart';
import '../models/saved_bed.dart';
import 'unit_buttons.dart';

const _suggestedNames = [
  'Tomato',
  'Cucumber',
  'Lettuce',
  'Kale',
  'Basil',
  'Pepper',
  'Carrot',
  'Zinnia',
];

Future<SavedPlanting?> showPlantingForm(
  BuildContext context, {
  SavedPlanting? existing,
}) {
  return showModalBottomSheet<SavedPlanting>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _PlantingFormSheet(existing: existing);
    },
  );
}

class _PlantingFormSheet extends StatefulWidget {
  final SavedPlanting? existing;

  const _PlantingFormSheet({this.existing});

  @override
  State<_PlantingFormSheet> createState() => _PlantingFormSheetState();
}

class _PlantingFormSheetState extends State<_PlantingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _inRowController = TextEditingController();
  final _betweenController = TextEditingController();
  final _perSqFtController = TextEditingController();

  BedUnit _unit = BedUnit.inches;
  SpacingMethod _method = SpacingMethod.row;
  List<WebPacketHit> _webHits = [];
  bool _webLoading = false;
  String? _webError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    _nameController.text = existing.label == 'Plant' ? '' : existing.label;
    if (existing.hasExplicitSpacing) {
      _applySaved(existing);
      return;
    }
    final plant = resolvePlanting(existing);
    if (plant != null) {
      _applyPlant(plant);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inRowController.dispose();
    _betweenController.dispose();
    _perSqFtController.dispose();
    super.dispose();
  }

  void _applySaved(SavedPlanting planting) {
    _unit = bedUnitFromName(planting.spacingUnit);
    _method = planting.method == 'squareFoot'
        ? SpacingMethod.squareFoot
        : SpacingMethod.row;
    _inRowController.text = planting.inRow ?? '';
    _betweenController.text = planting.betweenRow ?? '';
    _perSqFtController.text = planting.perSquareFoot ?? '';
  }

  void _applyPlant(Plant plant) {
    final next = plantingFromPlant(plant, unit: _unit);
    _nameController.text = plant.displayName;
    _method = plant.method;
    _inRowController.text = next.inRow ?? '';
    _betweenController.text = next.betweenRow ?? '';
    _perSqFtController.text = next.perSquareFoot ?? '';
  }

  void _applySuggestion(String query) {
    final matches = rankCatalogPlants(query);
    if (matches.isEmpty) {
      _nameController.text = query;
      return;
    }
    _applyPlant(matches.first);
  }

  void _applyWebHit(WebPacketHit hit) {
    final name = packetNameFromTitle(hit.title);
    final query = name.isEmpty ? hit.title : name;
    final matches = rankCatalogPlants(query);
    if (matches.isNotEmpty && plantMatchScore(matches.first, query) >= 70) {
      _applyPlant(matches.first);
    } else {
      _nameController.text = query;
    }
    _webHits = [];
    _webError = null;
  }

  Future<void> _searchWeb() async {
    final query = _nameController.text.trim();
    if (query.length < 2) {
      setState(() {
        _webError = 'Type a plant name, then search the web.';
      });
      return;
    }
    setState(() {
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
          _webError =
              'No web results this time. Pick a plant above, or type spacing yourself.';
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

  void _setUnit(BedUnit next) {
    if (next == _unit) {
      return;
    }
    void convert(TextEditingController controller) {
      final value = double.tryParse(controller.text.trim());
      if (value == null) {
        return;
      }
      controller.text = formatAmount(fromInches(toInches(value, _unit), next));
    }

    convert(_inRowController);
    convert(_betweenController);
    setState(() {
      _unit = next;
    });
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a number';
    }
    if (parsed <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a whole number';
    }
    if (parsed <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      SavedPlanting(
        name: _nameController.text.trim(),
        method: _method.name,
        inRow: _method == SpacingMethod.row
            ? _inRowController.text.trim()
            : null,
        betweenRow: _method == SpacingMethod.row
            ? _betweenController.text.trim()
            : null,
        perSquareFoot: _method == SpacingMethod.squareFoot
            ? _perSqFtController.text.trim()
            : null,
        spacingUnit: _unit.name,
        plantDisplayName: _nameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitName = bedUnitShort(_unit);
    final query = _nameController.text;
    final suggestions = rankCatalogPlants(query).take(8).toList();
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + inset),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                widget.existing == null ? 'Add a plant' : 'Edit plant',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Plant name',
                  hintText: 'Tomato, kale, zinnia…',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name this plant';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _searchWeb(),
              ),
              const SizedBox(height: 12),
              Text('Suggested plants', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in _suggestedNames)
                    ActionChip(
                      label: Text(name),
                      onPressed: () {
                        setState(() {
                          _applySuggestion(name);
                          _webHits = [];
                          _webError = null;
                        });
                      },
                    ),
                ],
              ),
              if (query.trim().isNotEmpty && suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final plant in suggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(plant.displayName),
                    subtitle: Text(plant.category),
                    onTap: () {
                      setState(() {
                        _applyPlant(plant);
                        _webHits = [];
                        _webError = null;
                      });
                    },
                  ),
              ],
              const SizedBox(height: 8),
              Row(
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
              if (_webError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _webError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              for (final hit in _webHits)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(hit.title),
                  subtitle: Text(
                    [
                      if (hit.brand != null) hit.brand!,
                      hit.snippet,
                    ].where((part) => part.isNotEmpty).join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() => _applyWebHit(hit)),
                ),
              const SizedBox(height: 16),
              Text('How to space it', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<SpacingMethod>(
                segments: const [
                  ButtonSegment(
                    value: SpacingMethod.row,
                    label: Text('Rows'),
                  ),
                  ButtonSegment(
                    value: SpacingMethod.squareFoot,
                    label: Text('Sq ft'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (selected) {
                  setState(() {
                    _method = selected.first;
                  });
                },
              ),
              if (_method == SpacingMethod.row) ...[
                const SizedBox(height: 16),
                Text('Spacing units', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                UnitButtons(value: _unit, onChanged: _setUnit),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _inRowController,
                  decoration: InputDecoration(
                    labelText: 'Space between plants ($unitName)',
                    hintText: 'How far apart in the row',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validatePositiveNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _betweenController,
                  decoration: InputDecoration(
                    labelText: 'Space between rows ($unitName)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validatePositiveNumber,
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _perSqFtController,
                  decoration: const InputDecoration(
                    labelText: 'Plants per square foot',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatePositiveInt,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Save plant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
