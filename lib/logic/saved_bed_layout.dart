import '../data/garden_seeds.dart';
import '../data/seed_packets.dart';
import '../data/starter_plants.dart';
import '../models/plant.dart';
import '../models/saved_bed.dart';
import 'bed_geometry.dart';
import 'packet_parser.dart';
import 'spacing_calculator.dart';
import 'unit_conversion.dart';

List<Plant> get catalogPlants => [
      ...starterPlants,
      ...seedPackets,
      ...gardenSeeds,
    ];

class PlantingLayout {
  final SavedPlanting planting;
  final Plant? plant;
  final PlantCountResult? result;
  final InchRect rect;

  const PlantingLayout({
    required this.planting,
    required this.plant,
    required this.result,
    required this.rect,
  });

  String get label => planting.label;
}

class SavedBedLayout {
  final SavedBed bed;
  final List<PlantingLayout> plantings;
  final double lengthIn;
  final double widthIn;

  const SavedBedLayout({
    required this.bed,
    required this.plantings,
    required this.lengthIn,
    required this.widthIn,
  });

  Plant? get plant => plantings.isEmpty ? null : plantings.first.plant;

  PlantCountResult? get result {
    if (plantings.length == 1) {
      return plantings.first.result;
    }
    final total = plantings.fold<int>(
      0,
      (sum, planting) => sum + (planting.result?.count ?? 0),
    );
    if (total <= 0) {
      return null;
    }
    return PlantCountResult(count: total);
  }

  String get plantLabel {
    final labels = [
      for (final planting in plantings) planting.label,
    ];
    if (labels.isEmpty) {
      return 'Unknown plant';
    }
    return labels.join(' + ');
  }

  String get sizeLabel {
    final unit = bedUnitFromName(bed.unit);
    return '${bed.length} × ${bed.width} ${bedUnitLabel(unit)}';
  }
}

SavedBedLayout layoutForSavedBed(SavedBed bed) {
  final unit = bedUnitFromName(bed.unit);
  final lengthValue = double.tryParse(bed.length) ?? 0;
  final widthValue = double.tryParse(bed.width) ?? 0;
  final lengthIn = toInches(lengthValue, unit);
  final widthIn = toInches(widthValue, unit);
  final entries = bed.allPlantings;
  return SavedBedLayout(
    bed: bed,
    lengthIn: lengthIn,
    widthIn: widthIn,
    plantings: [
      for (var i = 0; i < entries.length; i++)
        _layoutPlanting(
          entries[i],
          plantingToInchRect(
            planting: entries[i],
            masterUnit: unit,
            masterLengthIn: lengthIn,
            masterWidthIn: widthIn,
            index: i,
            count: entries.length,
          ),
        ),
    ],
  );
}

PlantingLayout _layoutPlanting(SavedPlanting planting, InchRect rect) {
  final plant = resolvePlanting(planting);
  final result = plant == null || rect.length <= 0 || rect.width <= 0
      ? null
      : calculatePlantLayout(plant, rect.length, rect.width);
  return PlantingLayout(
    planting: planting,
    plant: plant,
    result: result,
    rect: rect,
  );
}

Plant? resolvePlant(SavedBed bed) {
  final plantings = bed.allPlantings;
  if (plantings.isEmpty) {
    return null;
  }
  return resolvePlanting(plantings.first);
}

Plant? resolvePlanting(SavedPlanting planting) {
  final explicit = plantFromSavedPlanting(planting);
  if (explicit != null) {
    return explicit;
  }
  final name = planting.name ?? planting.plantDisplayName;
  if (name != null) {
    for (final plant in catalogPlants) {
      if (plant.displayName == name || plant.name == name) {
        return plant;
      }
    }
  }
  if (planting.packetText.trim().isNotEmpty) {
    return parseSeedPacketText(planting.packetText)?.plant;
  }
  return null;
}

Plant? plantFromSavedPlanting(SavedPlanting planting) {
  if (!planting.hasExplicitSpacing) {
    return null;
  }
  final unit = bedUnitFromName(planting.spacingUnit);
  final name = planting.label;
  if (planting.method == 'squareFoot') {
    final perSqFt = int.tryParse(planting.perSquareFoot!.trim());
    if (perSqFt == null || perSqFt <= 0) {
      return null;
    }
    return Plant(
      name: name,
      category: 'custom',
      method: SpacingMethod.squareFoot,
      perSquareFoot: perSqFt,
    );
  }
  final inRow = double.tryParse(planting.inRow!.trim());
  final between = double.tryParse(planting.betweenRow!.trim());
  if (inRow == null || between == null || inRow <= 0 || between <= 0) {
    return null;
  }
  return Plant(
    name: name,
    category: 'custom',
    method: SpacingMethod.row,
    inRowInches: toInches(inRow, unit),
    betweenRowInches: toInches(between, unit),
  );
}

SavedPlanting plantingFromPlant(Plant plant, {BedUnit unit = BedUnit.inches}) {
  return SavedPlanting(
    name: plant.displayName,
    method: plant.method.name,
    inRow: plant.inRowInches == null
        ? null
        : formatAmount(fromInches(plant.inRowInches!, unit)),
    betweenRow: plant.betweenRowInches == null
        ? null
        : formatAmount(fromInches(plant.betweenRowInches!, unit)),
    perSquareFoot: plant.perSquareFoot?.toString(),
    spacingUnit: unit.name,
    plantDisplayName: plant.displayName,
  );
}

String plantingLabel(SavedPlanting planting) => planting.label;

String plantingSpacingSummary(SavedPlanting planting) {
  final unit = bedUnitShort(bedUnitFromName(planting.spacingUnit));
  if (planting.method == 'squareFoot') {
    final count = planting.perSquareFoot?.trim();
    if (count == null || count.isEmpty) {
      return 'Square foot';
    }
    return '$count per sq ft';
  }
  final inRow = planting.inRow?.trim();
  final between = planting.betweenRow?.trim();
  if (inRow == null ||
      inRow.isEmpty ||
      between == null ||
      between.isEmpty) {
    return 'Row spacing';
  }
  return '$inRow $unit in row · $between $unit between rows';
}

SavedBed draftMasterFromBeds(List<SavedBed> beds) {
  final first = beds.first;
  final masterUnit = bedUnitFromName(first.unit);
  final masterLengthIn = toInches(double.tryParse(first.length) ?? 0, masterUnit);
  final masterWidthIn = toInches(double.tryParse(first.width) ?? 0, masterUnit);
  final seen = <String>{};
  final plantings = <SavedPlanting>[];
  final sizes = <InchRect>[];
  for (final bed in beds) {
    final sourceUnit = bedUnitFromName(bed.unit);
    final sourceLengthIn = toInches(
      double.tryParse(bed.length) ?? 0,
      sourceUnit,
    );
    final sourceWidthIn = toInches(double.tryParse(bed.width) ?? 0, sourceUnit);
    final sourcePlantings = bed.allPlantings;
    for (var i = 0; i < sourcePlantings.length; i++) {
      final planting = sourcePlantings[i];
      final key = [
        planting.label,
        planting.method,
        planting.inRow,
        planting.betweenRow,
        planting.perSquareFoot,
        planting.spacingUnit,
        planting.packetText,
      ].join('|');
      if (!seen.add(key)) {
        continue;
      }
      plantings.add(planting);
      if (planting.hasPlacement) {
        sizes.add(
          plantingToInchRect(
            planting: planting,
            masterUnit: sourceUnit,
            masterLengthIn: sourceLengthIn,
            masterWidthIn: sourceWidthIn,
            index: i,
            count: sourcePlantings.length,
          ).copyWith(x: 0, y: 0),
        );
      } else {
        sizes.add(
          InchRect(
            x: 0,
            y: 0,
            length: sourceLengthIn <= 0 ? masterLengthIn / 2 : sourceLengthIn,
            width: sourceWidthIn <= 0 ? masterWidthIn / 2 : sourceWidthIn,
          ),
        );
      }
    }
  }
  return SavedBed(
    name: '',
    length: first.length,
    width: first.width,
    unit: first.unit,
    icon: first.icon,
    plantings: packPlantingsIntoMaster(
      plantings: plantings,
      masterUnit: masterUnit,
      masterLengthIn: masterLengthIn,
      masterWidthIn: masterWidthIn,
      preferredSizes: sizes,
    ),
  );
}
