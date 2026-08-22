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

  test('parses mixed inch and feet row wording', () {
    final parsed = parseSeedPacketText(
      'Set plants 36 inches apart in rows 4 feet apart.',
    );
    expect(parsed, isNotNull);
    expect(parsed!.plant.inRowInches, 36);
    expect(parsed.plant.betweenRowInches, 48);
  });
}
