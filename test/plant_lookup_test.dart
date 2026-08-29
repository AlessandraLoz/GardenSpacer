import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/data/seed_packets.dart';
import 'package:garden_spacer/logic/plant_search.dart';

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

  test('lookup matches brand plus crop without the exact variety name', () {
    final results = rankCatalogPlants('burpee cucumber');
    expect(results, isNotEmpty);
    expect(results.first.brand, 'Burpee');
    expect(results.first.name.toLowerCase(), contains('cucumber'));
    expect(
      rankCatalogPlants('burpee cukes').first.name.toLowerCase(),
      contains('cucumber'),
    );
  });

  test('lookup finds common garden seeds by nickname', () {
    expect(rankCatalogPlants('cilantro').first.name, 'Cilantro');
    expect(rankCatalogPlants('coriander').first.name, 'Cilantro');
    expect(rankCatalogPlants('zinnia').first.name, 'Zinnia');
    expect(rankCatalogPlants('kale').first.name, 'Kale');
    expect(rankCatalogPlants('watermelon').first.category, 'fruit');
  });
}
