import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/logic/bed_geometry.dart';
import 'package:garden_spacer/logic/saved_bed_layout.dart';
import 'package:garden_spacer/logic/unit_conversion.dart';
import 'package:garden_spacer/models/saved_bed.dart';

void main() {
  test('legacy mixed beds become non-overlapping strips', () {
    const bed = SavedBed(
      name: 'Vegetables',
      length: '8',
      width: '4',
      unit: 'feet',
      plantings: [
        SavedPlanting(plantDisplayName: 'Tomato (indeterminate)'),
        SavedPlanting(plantDisplayName: 'Cucumber (trellised)'),
      ],
    );

    final layout = layoutForSavedBed(bed);
    expect(layout.plantings, hasLength(2));
    expect(layout.plantings[0].rect.width, 24);
    expect(layout.plantings[1].rect.width, 24);
    expect(layout.plantings[1].rect.y, 24);
    expect(rectsOverlap(layout.plantings[0].rect, layout.plantings[1].rect), isFalse);
    expect(
      layout.result!.count,
      layout.plantings[0].result!.count + layout.plantings[1].result!.count,
    );
  });

  test('plant count uses each sub-bed size, not the master', () {
    const bed = SavedBed(
      name: 'Vegetables',
      length: '8',
      width: '4',
      unit: 'feet',
      plantings: [
        SavedPlanting(
          plantDisplayName: 'Lettuce (leaf)',
          x: '0',
          y: '0',
          length: '4',
          width: '4',
          sizeUnit: 'feet',
        ),
        SavedPlanting(
          plantDisplayName: 'Lettuce (leaf)',
          x: '4',
          y: '0',
          length: '4',
          width: '2',
          sizeUnit: 'feet',
        ),
      ],
    );

    final layout = layoutForSavedBed(bed);
    expect(layout.plantings[0].rect.length, 48);
    expect(layout.plantings[0].rect.width, 48);
    expect(layout.plantings[1].rect.length, 48);
    expect(layout.plantings[1].rect.width, 24);
    expect(layout.plantings[0].result!.count, isNot(layout.plantings[1].result!.count));
  });

  test('converts sub-bed centimeters into master inches', () {
    const planting = SavedPlanting(
      name: 'Cucumber',
      method: 'row',
      inRow: '12',
      betweenRow: '18',
      spacingUnit: 'inches',
      x: '0',
      y: '0',
      length: '60',
      width: '30',
      sizeUnit: 'centimeters',
    );
    final rect = plantingToInchRect(
      planting: planting,
      masterUnit: BedUnit.feet,
      masterLengthIn: 96,
      masterWidthIn: 48,
      index: 0,
      count: 1,
    );
    expect(rect.length, closeTo(60 / 2.54, 0.01));
    expect(rect.width, closeTo(30 / 2.54, 0.01));
  });

  test('blocks overlapping placement', () {
    const a = InchRect(x: 0, y: 0, length: 40, width: 24);
    const b = InchRect(x: 20, y: 0, length: 40, width: 24);
    expect(rectsOverlap(a, b), isTrue);
    expect(
      placementAllowed(
        candidate: b,
        masterLengthIn: 96,
        masterWidthIn: 48,
        others: [a],
      ),
      isFalse,
    );
    const beside = InchRect(x: 40, y: 0, length: 40, width: 24);
    expect(
      placementAllowed(
        candidate: beside,
        masterLengthIn: 96,
        masterWidthIn: 48,
        others: [a],
      ),
      isTrue,
    );
  });

  test('blocks sub-beds that leave the master', () {
    const candidate = InchRect(x: 80, y: 0, length: 40, width: 24);
    expect(
      placementAllowed(
        candidate: candidate,
        masterLengthIn: 96,
        masterWidthIn: 48,
        others: const [],
      ),
      isFalse,
    );
  });

  test('uses typed spacing and unit instead of packet parsing', () {
    const bed = SavedBed(
      name: 'Cukes',
      length: '8',
      width: '4',
      unit: 'feet',
      plantings: [
        SavedPlanting(
          name: 'Cucumber',
          method: 'row',
          inRow: '30',
          betweenRow: '45',
          spacingUnit: 'centimeters',
        ),
      ],
    );

    final plant = resolvePlanting(bed.allPlantings.single);
    expect(plant, isNotNull);
    expect(plant!.inRowInches, closeTo(30 / 2.54, 0.01));
    expect(plant.betweenRowInches, closeTo(45 / 2.54, 0.01));
    expect(layoutForSavedBed(bed).result, isNotNull);
  });

  test('combining gardens keeps unique plantings and first bed size', () {
    const tomato = SavedBed(
      name: 'Tomatoes',
      length: '8',
      width: '4',
      unit: 'feet',
      icon: 'sunny',
      plantDisplayName: 'Tomato (indeterminate)',
    );
    const cucumber = SavedBed(
      name: 'Cukes',
      length: '6',
      width: '3',
      unit: 'feet',
      plantDisplayName: 'Cucumber (trellised)',
    );

    final draft = draftMasterFromBeds([tomato, cucumber]);
    expect(draft.name, isEmpty);
    expect(draft.length, '8');
    expect(draft.width, '4');
    expect(draft.icon, 'sunny');
    expect(draft.allPlantings, hasLength(2));
    expect(draft.allPlantings.every((planting) => planting.hasPlacement), isTrue);
    final layout = layoutForSavedBed(draft);
    expect(
      rectsOverlap(layout.plantings[0].rect, layout.plantings[1].rect),
      isFalse,
    );
  });
}
