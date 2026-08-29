import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_spacer/data/bed_store.dart';
import 'package:garden_spacer/models/saved_bed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('upserts a named bed and overwrites the same name', () async {
    final store = BedStore();
    await store.upsert(
      const SavedBed(
        name: 'Back bed',
        length: '5',
        width: '5',
        unit: 'feet',
        plantDisplayName: 'Burpee · Better Boy Hybrid Tomato',
      ),
    );
    await store.upsert(
      const SavedBed(
        name: 'back bed',
        length: '8',
        width: '4',
        unit: 'feet',
        plantDisplayName: 'Lettuce (leaf)',
      ),
    );

    final beds = await store.loadAll();
    expect(beds, hasLength(1));
    expect(beds.first.name, 'back bed');
    expect(beds.first.length, '8');
  });

  test('round-trips icon and mixed plantings', () async {
    final store = BedStore();
    await store.upsert(
      const SavedBed(
        name: 'Vegetables',
        length: '8',
        width: '4',
        unit: 'feet',
        icon: 'bowl',
        plantings: [
          SavedPlanting(plantDisplayName: 'Tomato (indeterminate)'),
          SavedPlanting(plantDisplayName: 'Cucumber (trellised)'),
        ],
      ),
    );

    final beds = await store.loadAll();
    expect(beds.single.icon, 'bowl');
    expect(beds.single.allPlantings, hasLength(2));
    expect(
      beds.single.allPlantings.map((planting) => planting.plantDisplayName),
      ['Tomato (indeterminate)', 'Cucumber (trellised)'],
    );
  });
}
