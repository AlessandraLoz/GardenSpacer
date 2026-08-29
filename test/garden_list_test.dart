import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/logic/garden_list.dart';
import 'package:garden_spacer/models/saved_bed.dart';

void main() {
  const tomato = SavedBed(
    name: 'Tomatoes',
    length: '8',
    width: '4',
    unit: 'feet',
    plantDisplayName: 'Tomato (indeterminate)',
  );
  const mixed = SavedBed(
    name: 'Vegetables',
    length: '8',
    width: '4',
    unit: 'feet',
    plantings: [
      SavedPlanting(plantDisplayName: 'Tomato (indeterminate)'),
      SavedPlanting(plantDisplayName: 'Cucumber (trellised)'),
    ],
  );

  test('treats more than one planting as a master bed', () {
    expect(tomato.isMaster, isFalse);
    expect(mixed.isMaster, isTrue);
  });

  test('groups master beds before single-plant beds', () {
    final sections = gardenListSections([tomato, mixed], GardenKindFilter.all);
    expect(sections.map((section) => section.title), [
      'Master beds',
      'Single-plant beds',
    ]);
    expect(sections.first.beds.single.name, 'Vegetables');
    expect(sections.last.beds.single.name, 'Tomatoes');
  });

  test('filters to master or single-plant beds', () {
    expect(
      gardenListSections([tomato, mixed], GardenKindFilter.master)
          .single
          .beds
          .single
          .name,
      'Vegetables',
    );
    expect(
      gardenListSections([tomato, mixed], GardenKindFilter.single)
          .single
          .beds
          .single
          .name,
      'Tomatoes',
    );
  });
}
