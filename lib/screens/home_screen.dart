import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/starter_plants.dart';
import '../logic/spacing_calculator.dart';
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

  Plant? _selectedPlant;
  int? _plantCount;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final length = double.parse(_lengthController.text.trim());
    final width = double.parse(_widthController.text.trim());

    setState(() {
      _plantCount = calculatePlantCount(_selectedPlant!, length, width);
    });
  }

  String? _validateInches(String? value) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Bed length (inches)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validateInches,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(
                  labelText: 'Bed width (inches)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validateInches,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Plant>(
                initialValue: _selectedPlant,
                decoration: const InputDecoration(
                  labelText: 'Plant',
                  border: OutlineInputBorder(),
                ),
                items: starterPlants
                    .map(
                      (plant) => DropdownMenuItem(
                        value: plant,
                        child: Text(plant.name),
                      ),
                    )
                    .toList(),
                onChanged: (plant) {
                  setState(() {
                    _selectedPlant = plant;
                    _plantCount = null;
                  });
                },
                validator: (plant) => plant == null ? 'Select a plant' : null,
              ),
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
