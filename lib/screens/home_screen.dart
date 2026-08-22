import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/seed_packets.dart';
import '../data/starter_plants.dart';
import '../logic/packet_parser.dart';
import '../logic/spacing_calculator.dart';
import '../logic/unit_conversion.dart';
import '../models/plant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _packetController = TextEditingController();

  BedUnit _unit = BedUnit.inches;
  Plant? _selectedPlant;
  PacketParseResult? _parsedPacket;
  String? _packetError;
  int? _plantCount;

  List<Plant> get _catalogPlants => [...starterPlants, ...seedPackets];

  @override
  void dispose() {
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
      _plantCount = null;
    });
  }

  void _calculate() {
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
          _plantCount = null;
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

    setState(() {
      _plantCount = calculatePlantCount(plant!, length, width);
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
              DropdownButtonFormField<BedUnit>(
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
                    _plantCount = null;
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
                    _plantCount = null;
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
                child: const Text('Calculate'),
              ),
              const SizedBox(height: 40),
              if (_plantCount != null)
                Column(
                  children: [
                    Text(
                      '$_plantCount',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _plantCount == 1 ? 'plant fits' : 'plants fit',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
