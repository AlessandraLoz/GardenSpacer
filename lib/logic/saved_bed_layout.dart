import '../data/seed_packets.dart';
import '../data/starter_plants.dart';
import '../models/plant.dart';
import '../models/saved_bed.dart';
import 'packet_parser.dart';
import 'spacing_calculator.dart';
import 'unit_conversion.dart';

List<Plant> get catalogPlants => [...starterPlants, ...seedPackets];

class SavedBedLayout {
  final SavedBed bed;
  final Plant? plant;
  final PlantCountResult? result;
  final double lengthIn;
  final double widthIn;

  const SavedBedLayout({
    required this.bed,
    required this.plant,
    required this.result,
    required this.lengthIn,
    required this.widthIn,
  });

  String get plantLabel {
    if (bed.packetText.trim().isNotEmpty) {
      return plant?.name ?? 'Custom packet';
    }
    return bed.plantDisplayName ?? plant?.displayName ?? 'Unknown plant';
  }

  String get sizeLabel {
    final unit = _unitFor(bed);
    return '${bed.length} × ${bed.width} ${bedUnitLabel(unit)}';
  }
}

SavedBedLayout layoutForSavedBed(SavedBed bed) {
  final unit = _unitFor(bed);
  final lengthValue = double.tryParse(bed.length) ?? 0;
  final widthValue = double.tryParse(bed.width) ?? 0;
  final lengthIn = toInches(lengthValue, unit);
  final widthIn = toInches(widthValue, unit);
  final plant = resolvePlant(bed);
  final result = plant == null || lengthIn <= 0 || widthIn <= 0
      ? null
      : calculatePlantLayout(plant, lengthIn, widthIn);
  return SavedBedLayout(
    bed: bed,
    plant: plant,
    result: result,
    lengthIn: lengthIn,
    widthIn: widthIn,
  );
}

Plant? resolvePlant(SavedBed bed) {
  if (bed.packetText.trim().isNotEmpty) {
    return parseSeedPacketText(bed.packetText)?.plant;
  }
  final name = bed.plantDisplayName;
  if (name == null) {
    return null;
  }
  for (final plant in catalogPlants) {
    if (plant.displayName == name) {
      return plant;
    }
  }
  return null;
}

BedUnit _unitFor(SavedBed bed) {
  return BedUnit.values.firstWhere(
    (value) => value.name == bed.unit,
    orElse: () => BedUnit.inches,
  );
}
