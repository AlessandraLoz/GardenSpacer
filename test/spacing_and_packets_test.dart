import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/logic/packet_parser.dart';
import 'package:garden_spacer/logic/spacing_calculator.dart';
import 'package:garden_spacer/logic/unit_conversion.dart';
import 'package:garden_spacer/models/plant.dart';

void main() {
  test('converts bed units to inches', () {
    expect(toInches(8, BedUnit.feet), 96);
    expect(toInches(4, BedUnit.feet), 48);
    expect(toInches(254, BedUnit.centimeters), closeTo(100, 0.01));
    expect(toInches(25.4, BedUnit.millimeters), closeTo(1, 0.01));
    expect(toInches(1, BedUnit.meters), closeTo(39.37007874, 0.0001));
  });

  test('feet bed matches known lettuce count', () {
    final lettuce = Plant(
      name: 'Lettuce (leaf)',
      category: 'vegetable',
      method: SpacingMethod.squareFoot,
      perSquareFoot: 4,
    );
    expect(
      calculatePlantCount(
        lettuce,
        toInches(8, BedUnit.feet),
        toInches(4, BedUnit.feet),
      ),
      128,
    );
  });

  test('parses square-foot packet text', () {
    final parsed = parseSeedPacketText('4 plants per square foot');
    expect(parsed, isNotNull);
    expect(parsed!.plant.method, SpacingMethod.squareFoot);
    expect(parsed.plant.perSquareFoot, 4);
  });

  test('parses row packet text with thin-to and rows', () {
    final parsed = parseSeedPacketText('Thin to 4" apart. Rows 18" apart.');
    expect(parsed, isNotNull);
    expect(parsed!.plant.method, SpacingMethod.row);
    expect(parsed.plant.inRowInches, 4);
    expect(parsed.plant.betweenRowInches, 18);
  });

  test('5x5 ft Burpee Better Boy fits a 2x2 grid', () {
    final tomato = Plant(
      name: 'Better Boy Hybrid Tomato',
      brand: 'Burpee',
      category: 'vegetable',
      method: SpacingMethod.row,
      inRowInches: 36,
      betweenRowInches: 48,
    );
    expect(
      calculatePlantCount(
        tomato,
        toInches(5, BedUnit.feet),
        toInches(5, BedUnit.feet),
      ),
      4,
    );
  });

  test('parses mixed inch and feet row wording', () {
    final parsed = parseSeedPacketText(
      'Set plants 36 inches apart in rows 4 feet apart.',
    );
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, 36);
    expect(parsed.plant.betweenRowInches, 48);
  });

  test('parses thin-to ranges in centimeters', () {
    final parsed = parseSeedPacketText(
      'Thin to 2 to 3 cm. Rows 30 cm apart.',
    );
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, closeTo(3 / 2.54, 0.01));
    expect(parsed.plant.betweenRowInches, closeTo(30 / 2.54, 0.01));
  });

  test('parses 30 x 45 cm as row spacing', () {
    final parsed = parseSeedPacketText('Sow 30 x 45 cm.');
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, closeTo(30 / 2.54, 0.01));
    expect(parsed.plant.betweenRowInches, closeTo(45 / 2.54, 0.01));
  });

  test('parses plants per sqft shorthand', () {
    final parsed = parseSeedPacketText('16 per sqft');
    expect(parsed, isNotNull);
    expect(parsed!.plant.perSquareFoot, 16);
  });

  test('parses labeled row spacing and ignores tiny seed spacing', () {
    final parsed = parseSeedPacketText(
      'Seed Spacing: 1/2 inch Row Spacing: 3-4 feet Set plants 24 inches apart',
    );
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, 24);
    expect(parsed.plant.betweenRowInches, 48);
  });

  test('uses a single apart spacing as a square grid', () {
    final parsed = parseSeedPacketText('Space 12 inches apart.');
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, 12);
    expect(parsed.plant.betweenRowInches, 12);
  });
}
