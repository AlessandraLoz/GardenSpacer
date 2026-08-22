import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bed_store.dart';
import '../data/seed_packets.dart';
import '../data/starter_plants.dart';
import '../logic/packet_parser.dart';
import '../logic/spacing_calculator.dart';
import '../logic/unit_conversion.dart';
import '../models/plant.dart';
import '../models/saved_bed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _packetController = TextEditingController();
  final _store = BedStore();

  BedUnit _unit = BedUnit.inches;
  Plant? _selectedPlant;
  PacketParseResult? _parsedPacket;
  String? _packetError;
  PlantCountResult? _result;
  List<SavedBed> _savedBeds = [];
  String? _loadedName;
  String? _saveMessage;
  int _formTick = 0;

  List<Plant> get _catalogPlants => [...starterPlants, ...seedPackets];

  @override
  void initState() {
    super.initState();
    _loadSavedBeds();
  }

  Future<void> _loadSavedBeds() async {
    final beds = await _store.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedBeds = beds;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _packetController.dispose();
    super.dispose();
  }

  void _onPacketTextChanged(String value) {
    final parsed = parseSeedPacketText(value);
    setState(() {
      _parsedPacket = parsed;
      _packetError = value.trim().isEmpty
          ? null
          : (parsed == null
              ? 'Could not find spacing. Include in-row and row spacing, or plants per square foot.'
              : null);
      _result = null;
      _saveMessage = null;
    });
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final packetText = _packetController.text.trim();
    Plant? plant;
    if (packetText.isNotEmpty) {
      final parsed = parseSeedPacketText(packetText);
      if (parsed == null) {
        setState(() {
          _packetError =
              'Could not find spacing. Include in-row and row spacing, or plants per square foot.';
          _result = null;
        });
        return;
      }
      plant = parsed.plant;
    } else {
      plant = _selectedPlant;
    }

    if (plant == null) {
      return;
    }

    final length = toInches(
      double.parse(_lengthController.text.trim()),
      _unit,
    );
    final width = toInches(
      double.parse(_widthController.text.trim()),
      _unit,
    );

    final name = _nameController.text.trim();
    final saved = SavedBed(
      name: name,
      length: _lengthController.text.trim(),
      width: _widthController.text.trim(),
      unit: _unit.name,
      plantDisplayName: packetText.isNotEmpty ? null : plant.displayName,
      packetText: packetText,
    );
    final beds = await _store.upsert(saved);
    if (!mounted) {
      return;
    }

    setState(() {
      _result = calculatePlantLayout(plant!, length, width);
      _savedBeds = beds;
      _loadedName = name;
      _saveMessage = 'Saved as $name';
    });
  }

  void _applySaved(SavedBed bed) {
    final unit = BedUnit.values.firstWhere(
      (value) => value.name == bed.unit,
      orElse: () => BedUnit.inches,
    );
    Plant? plant;
    if (bed.plantDisplayName != null) {
      for (final candidate in _catalogPlants) {
        if (candidate.displayName == bed.plantDisplayName) {
          plant = candidate;
          break;
        }
      }
    }
    final parsed = parseSeedPacketText(bed.packetText);
    setState(() {
      _formTick++;
      _loadedName = bed.name;
      _nameController.text = bed.name;
      _lengthController.text = bed.length;
      _widthController.text = bed.width;
      _unit = unit;
      _selectedPlant = plant;
      _packetController.text = bed.packetText;
      _parsedPacket = parsed;
      _packetError = null;
      _result = null;
      _saveMessage = null;
    });
  }

  Future<void> _deleteLoaded() async {
    final name = _loadedName;
    if (name == null) {
      return;
    }
    final beds = await _store.delete(name);
    if (!mounted) {
      return;
    }
    setState(() {
      _savedBeds = beds;
      _loadedName = null;
      _saveMessage = 'Deleted $name';
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name this bed to save it';
    }
    return null;
  }

  String? _validatePlant(Plant? plant) {
    if (_packetController.text.trim().isNotEmpty) {
      return null;
    }
    return plant == null ? 'Select a plant or paste a packet' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitName = bedUnitLabel(_unit);
    final selectedExtract = _selectedPlant?.packetExtract;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GardenSpacer'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_savedBeds.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          'saved-$_formTick-${_savedBeds.map((bed) => bed.name).join(',')}',
                        ),
                        initialValue: _loadedName,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Saved beds',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final bed in _savedBeds)
                            DropdownMenuItem(
                              value: bed.name,
                              child: Text(
                                bed.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (name) {
                          if (name == null) {
                            return;
                          }
                          for (final bed in _savedBeds) {
                            if (bed.name == name) {
                              _applySaved(bed);
                              return;
                            }
                          }
                        },
                      ),
                    ),
                    if (_loadedName != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Delete saved bed',
                        onPressed: _deleteLoaded,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Bed name',
                  hintText: 'Back bed, tomatoes',
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BedUnit>(
                key: ValueKey('unit-$_formTick-$_unit'),
                initialValue: _unit,
                decoration: const InputDecoration(
                  labelText: 'Bed size units',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final unit in BedUnit.values)
                    DropdownMenuItem(
                      value: unit,
                      child: Text(bedUnitLabel(unit)),
                    ),
                ],
                onChanged: (unit) {
                  if (unit == null) {
                    return;
                  }
                  setState(() {
                    _unit = unit;
                    _result = null;
                    _saveMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lengthController,
                decoration: InputDecoration(
                  labelText: 'Bed length ($unitName)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: InputDecoration(
                  labelText: 'Bed width ($unitName)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Plant>(
                key: ValueKey(
                  'plant-$_formTick-${_selectedPlant?.displayName}',
                ),
                initialValue: _selectedPlant,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Plant or seed packet',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final plant in _catalogPlants)
                    DropdownMenuItem(
                      value: plant,
                      child: Text(
                        plant.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (plant) {
                  setState(() {
                    _selectedPlant = plant;
                    _result = null;
                    _saveMessage = null;
                  });
                },
                validator: _validatePlant,
              ),
              if (selectedExtract != null) ...[
                const SizedBox(height: 8),
                Text(
                  selectedExtract,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _packetController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Or paste seed packet text',
                  hintText:
                      'Example: Thin to 4" apart. Rows 18" apart.\nOr: 4 plants per square foot.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: _onPacketTextChanged,
              ),
              if (_parsedPacket != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Using ${_parsedPacket!.explanation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (_packetError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _packetError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _calculate,
                child: const Text('Calculate and save'),
              ),
              if (_saveMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              if (_result != null)
                Column(
                  children: [
                    Text(
                      '${_result!.count}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.count == 1 ? 'plant fits' : 'plants fit',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (_result!.rows != null && _result!.perRow != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_result!.rows} rows × ${_result!.perRow} per row',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
