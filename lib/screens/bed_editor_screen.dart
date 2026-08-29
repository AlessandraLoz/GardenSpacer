import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bed_store.dart';
import '../logic/packet_parser.dart';
import '../logic/saved_bed_layout.dart';
import '../logic/unit_conversion.dart';
import '../models/plant.dart';
import '../models/saved_bed.dart';
import '../widgets/plant_lookup.dart';

class BedEditorScreen extends StatefulWidget {
  final SavedBed? existing;

  const BedEditorScreen({super.key, this.existing});

  @override
  State<BedEditorScreen> createState() => _BedEditorScreenState();
}

class _BedEditorScreenState extends State<BedEditorScreen> {
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
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final layout = layoutForSavedBed(existing);
      _nameController.text = existing.name;
      _lengthController.text = existing.length;
      _widthController.text = existing.width;
      _unit = BedUnit.values.firstWhere(
        (value) => value.name == existing.unit,
        orElse: () => BedUnit.inches,
      );
      _packetController.text = existing.packetText;
      _parsedPacket = parseSeedPacketText(existing.packetText);
      _selectedPlant = existing.packetText.trim().isEmpty ? layout.plant : null;
    }
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
              ? 'Could not find spacing. Try “thin to 4 inches, rows 18 inches” or “4 per sq ft”.'
              : null);
    });
  }

  Future<void> _save() async {
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
              'Could not find spacing. Try “thin to 4 inches, rows 18 inches” or “4 per sq ft”.';
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

    final oldName = widget.existing?.name;
    final name = _nameController.text.trim();
    final saved = SavedBed(
      name: name,
      length: _lengthController.text.trim(),
      width: _widthController.text.trim(),
      unit: _unit.name,
      plantDisplayName: packetText.isNotEmpty ? null : plant.displayName,
      packetText: packetText,
    );

    if (oldName != null && oldName.toLowerCase() != name.toLowerCase()) {
      await _store.delete(oldName);
    }
    await _store.upsert(saved);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(saved);
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
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit bed' : 'New bed'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
              FormField<Plant>(
                initialValue: _selectedPlant,
                validator: _validatePlant,
                builder: (field) {
                  return InkWell(
                    onTap: () async {
                      final picked = await showPlantLookup(
                        context,
                        selected: _selectedPlant,
                      );
                      if (picked == null) {
                        return;
                      }
                      setState(() {
                        _selectedPlant = picked;
                      });
                      field.didChange(picked);
                    },
                    child: InputDecorator(
                      isEmpty: _selectedPlant == null,
                      decoration: InputDecoration(
                        labelText: 'Plant or seed packet',
                        hintText: 'Search packets',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.search),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _selectedPlant?.displayName ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
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
                      'Thin to 2 to 3 cm. Rows 30 cm apart.\nOr: 16 per sq ft.\nOr: 30 x 45 cm.',
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
                onPressed: _save,
                child: const Text('Calculate and save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
