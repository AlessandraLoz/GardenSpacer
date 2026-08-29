import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/data/seed_packets.dart';
import 'package:garden_spacer/widgets/plant_lookup.dart';

void main() {
  test('lookup matches brand, variety, and packet wording', () {
    final tomato = seedPackets.firstWhere(
      (plant) => plant.name.contains('Better Boy'),
    );
    expect(plantMatchesQuery(tomato, 'burpee'), isTrue);
    expect(plantMatchesQuery(tomato, 'tomato'), isTrue);
    expect(plantMatchesQuery(tomato, '36"'), isTrue);
    expect(plantMatchesQuery(tomato, 'zucchini'), isFalse);
    expect(plantMatchScore(tomato, tomato.displayName), 100);
    expect(rankCatalogPlants(tomato.displayName).first.displayName, tomato.displayName);
  });
}
