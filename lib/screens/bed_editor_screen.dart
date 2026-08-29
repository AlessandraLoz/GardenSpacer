import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bed_store.dart';
import '../logic/bed_geometry.dart';
import '../logic/saved_bed_layout.dart';
import '../logic/unit_conversion.dart';
import '../models/saved_bed.dart';
import '../theme/garden_icons.dart';
import '../widgets/bed_placement_canvas.dart';
import '../widgets/bed_sketch.dart';
import '../widgets/planting_form.dart';
import '../widgets/unit_buttons.dart';

class BedEditorScreen extends StatefulWidget {
  final SavedBed? existing;
  final SavedBed? draft;

  const BedEditorScreen({super.key, this.existing, this.draft});

  @override
  State<BedEditorScreen> createState() => _BedEditorScreenState();
}

class _BedEditorScreenState extends State<BedEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _subXController = TextEditingController();
  final _subYController = TextEditingController();
  final _subLengthController = TextEditingController();
  final _subWidthController = TextEditingController();
  final _store = BedStore();

  BedUnit _unit = BedUnit.inches;
  BedUnit _subSizeUnit = BedUnit.inches;
  String _icon = 'eco';
  List<SavedPlanting> _plantings = [];
  int? _selected;
  String? _plantError;

  @override
  void initState() {
    super.initState();
    final source = widget.existing ?? widget.draft;
    if (source != null) {
      _nameController.text = source.name;
      _lengthController.text = source.length;
      _widthController.text = source.width;
      _unit = bedUnitFromName(source.unit);
      _icon = source.icon;
      _plantings = [...source.allPlantings];
      if (_plantings.isNotEmpty) {
        _selected = 0;
        _fillSubFields(_plantings.first);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _subXController.dispose();
    _subYController.dispose();
    _subLengthController.dispose();
    _subWidthController.dispose();
    super.dispose();
  }

  (double, double) _masterInches() {
    final length = toInches(double.tryParse(_lengthController.text) ?? 0, _unit);
    final width = toInches(double.tryParse(_widthController.text) ?? 0, _unit);
    return (length, width);
  }

  List<InchRect> _rects() {
    final master = _masterInches();
    return plantingRectsInches(
      plantings: _plantings,
      masterUnit: _unit,
      masterLengthIn: master.$1,
      masterWidthIn: master.$2,
    );
  }

  void _onMasterSizeEditingComplete() {
    _clampToMaster();
  }

  void _clampToMaster() {
    final master = _masterInches();
    if (master.$1 <= 0 || master.$2 <= 0 || _plantings.isEmpty) {
      return;
    }
    final next = clampPlantingsToMaster(
      plantings: _plantings,
      masterUnit: _unit,
      masterLengthIn: master.$1,
      masterWidthIn: master.$2,
    );
    setState(() {
      _plantings = next;
      if (_selected != null && _selected! < next.length) {
        _fillSubFields(next[_selected!]);
      }
    });
  }

  void _fillSubFields(SavedPlanting planting) {
    final master = _masterInches();
    final index = _selected ?? 0;
    final rect = plantingToInchRect(
      planting: planting,
      masterUnit: _unit,
      masterLengthIn: master.$1,
      masterWidthIn: master.$2,
      index: index < 0 ? 0 : index,
      count: _plantings.length,
    );
    _subSizeUnit = bedUnitFromName(planting.sizeUnit ?? _unit.name);
    _subXController.text = formatAmount(fromInches(rect.x, _unit));
    _subYController.text = formatAmount(fromInches(rect.y, _unit));
    _subLengthController.text = formatAmount(
      fromInches(rect.length, _subSizeUnit),
    );
    _subWidthController.text = formatAmount(
      fromInches(rect.width, _subSizeUnit),
    );
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _fillSubFields(_plantings[index]);
    });
  }

  void _moveRect(int index, InchRect rect) {
    setState(() {
      _plantings = [
        for (var i = 0; i < _plantings.length; i++)
          if (i == index)
            plantingWithRect(_plantings[i], rect, _unit)
          else
            _plantings[i],
      ];
      _selected = index;
      _fillSubFields(_plantings[index]);
    });
  }

  void _applySubFields() {
    final index = _selected;
    if (index == null || index >= _plantings.length) {
      return;
    }
    final master = _masterInches();
    final x = toInches(double.tryParse(_subXController.text) ?? 0, _unit);
    final y = toInches(double.tryParse(_subYController.text) ?? 0, _unit);
    final length = toInches(
      double.tryParse(_subLengthController.text) ?? 0,
      _subSizeUnit,
    );
    final width = toInches(
      double.tryParse(_subWidthController.text) ?? 0,
      _subSizeUnit,
    );
    final candidate = InchRect(x: x, y: y, length: length, width: width);
    final others = [
      for (var i = 0; i < _plantings.length; i++)
        if (i != index) _rects()[i],
    ];
    if (!placementAllowed(
      candidate: candidate,
      masterLengthIn: master.$1,
      masterWidthIn: master.$2,
      others: others,
    )) {
      setState(() {
        _plantError = 'That size or position overlaps another bed or the edge.';
        _fillSubFields(_plantings[index]);
      });
      return;
    }
    setState(() {
      _plantError = null;
      _plantings = [
        for (var i = 0; i < _plantings.length; i++)
          if (i == index)
            plantingWithRect(
              _plantings[i].copyWith(sizeUnit: _subSizeUnit.name),
              candidate,
              _unit,
            )
          else
            _plantings[i],
      ];
    });
  }

  Future<void> _addOrEditPlant({int? index}) async {
    final saved = await showPlantingForm(
      context,
      existing: index == null ? null : _plantings[index],
    );
    if (saved == null) {
      return;
    }
    final master = _masterInches();
    setState(() {
      _plantError = null;
      if (index == null) {
        final placed = master.$1 > 0 && master.$2 > 0
            ? placeNewPlanting(
                planting: saved,
                existing: _plantings,
                masterUnit: _unit,
                masterLengthIn: master.$1,
                masterWidthIn: master.$2,
              )
            : saved;
        _plantings = [..._plantings, placed];
        _selected = _plantings.length - 1;
        _fillSubFields(_plantings.last);
      } else {
        final current = _plantings[index];
        final merged = saved.copyWith(
          x: current.x,
          y: current.y,
          length: current.length,
          width: current.width,
          sizeUnit: current.sizeUnit,
        );
        _plantings = [
          for (var i = 0; i < _plantings.length; i++)
            if (i == index) merged else _plantings[i],
        ];
        _selected = index;
        _fillSubFields(_plantings[index]);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_plantings.isEmpty) {
      setState(() {
        _plantError = 'Add at least one plant.';
      });
      return;
    }

    final master = _masterInches();
    final plantings = master.$1 > 0 && master.$2 > 0
        ? clampPlantingsToMaster(
            plantings: _plantings,
            masterUnit: _unit,
            masterLengthIn: master.$1,
            masterWidthIn: master.$2,
          )
        : _plantings;

    final oldName = widget.existing?.name;
    final name = _nameController.text.trim();
    final saved = SavedBed(
      name: name,
      length: _lengthController.text.trim(),
      width: _widthController.text.trim(),
      unit: _unit.name,
      icon: _icon,
      plantings: plantings,
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
      return 'Name this garden to save it';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitName = bedUnitShort(_unit);
    final editing = widget.existing != null;
    final combining = widget.draft != null && widget.existing == null;
    final master = _masterInches();
    final rects = _rects();
    final colors = gardenCropColors(theme.colorScheme);
    final showCanvas = _plantings.isNotEmpty && master.$1 > 0 && master.$2 > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit garden'
              : combining
                  ? 'Master garden'
                  : 'New garden',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Icon', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in gardenIconIds)
                    Tooltip(
                      message: id,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _icon = id;
                          });
                        },
                        customBorder: const CircleBorder(),
                        child: Ink(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _icon == id
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: _icon == id
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: _icon == id ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            gardenIconData(id),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Garden name',
                  hintText: 'Vegetables, back bed, tomatoes',
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              Text('Master bed units', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              UnitButtons(
                value: _unit,
                onChanged: (unit) {
                  setState(() {
                    _unit = unit;
                    if (_selected != null) {
                      _fillSubFields(_plantings[_selected!]);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lengthController,
                decoration: InputDecoration(
                  labelText: 'Master length ($unitName)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validatePositiveNumber,
                onEditingComplete: _onMasterSizeEditingComplete,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: InputDecoration(
                  labelText: 'Master width ($unitName)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validatePositiveNumber,
                onEditingComplete: _onMasterSizeEditingComplete,
              ),
              const SizedBox(height: 24),
              Text('Sub-beds', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Each plant is its own rectangle. Drag to place it, use the corner handle to resize, or type length and width. Sub-beds stay inside the master bed and cannot overlap.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (showCanvas) ...[
                const SizedBox(height: 16),
                BedPlacementCanvas(
                  masterLengthIn: master.$1,
                  masterWidthIn: master.$2,
                  rects: rects,
                  labels: [for (final planting in _plantings) planting.label],
                  colors: [
                    for (var i = 0; i < _plantings.length; i++)
                      colors[i % colors.length],
                  ],
                  selectedIndex: _selected,
                  onSelect: _select,
                  onMove: _moveRect,
                ),
              ],
              const SizedBox(height: 8),
              if (_plantings.isEmpty)
                Text(
                  'No plants yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              for (var i = 0; i < _plantings.length; i++)
                ListTile(
                  selected: _selected == i,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors[i % colors.length],
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  title: Text(_plantings[i].label),
                  subtitle: Text(plantingSpacingSummary(_plantings[i])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit plant',
                        onPressed: () => _addOrEditPlant(index: i),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            _plantings = [
                              for (var j = 0; j < _plantings.length; j++)
                                if (j != i) _plantings[j],
                            ];
                            if (_plantings.isEmpty) {
                              _selected = null;
                            } else {
                              _selected = (_selected ?? 0).clamp(
                                0,
                                _plantings.length - 1,
                              );
                              _fillSubFields(_plantings[_selected!]);
                            }
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  onTap: () => _select(i),
                ),
              if (_selected != null && _plantings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected sub-bed size',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                UnitButtons(
                  value: _subSizeUnit,
                  onChanged: (unit) {
                    final length = toInches(
                      double.tryParse(_subLengthController.text) ?? 0,
                      _subSizeUnit,
                    );
                    final width = toInches(
                      double.tryParse(_subWidthController.text) ?? 0,
                      _subSizeUnit,
                    );
                    setState(() {
                      _subSizeUnit = unit;
                      _subLengthController.text = formatAmount(
                        fromInches(length, unit),
                      );
                      _subWidthController.text = formatAmount(
                        fromInches(width, unit),
                      );
                    });
                    _applySubFields();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subLengthController,
                        decoration: InputDecoration(
                          labelText: 'Length (${bedUnitShort(_subSizeUnit)})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onEditingComplete: _applySubFields,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _subWidthController,
                        decoration: InputDecoration(
                          labelText: 'Width (${bedUnitShort(_subSizeUnit)})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onEditingComplete: _applySubFields,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subXController,
                        decoration: InputDecoration(
                          labelText: 'X (${bedUnitShort(_unit)})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onEditingComplete: _applySubFields,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _subYController,
                        decoration: InputDecoration(
                          labelText: 'Y (${bedUnitShort(_unit)})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onEditingComplete: _applySubFields,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _applySubFields,
                    child: const Text('Apply size and position'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addOrEditPlant,
                icon: const Icon(Icons.add),
                label: const Text('Add a plant'),
              ),
              if (_plantError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _plantError!,
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
