import '../models/plant.dart';
import 'saved_bed_layout.dart';

const _synonyms = {
  'cuke': 'cucumber',
  'cukes': 'cucumber',
  'tomatoes': 'tomato',
  'peppers': 'pepper',
  'beans': 'bean',
  'peas': 'pea',
  'zukes': 'zucchini',
  'courgette': 'zucchini',
  'coriander': 'cilantro',
  'rocket': 'arugula',
  'maize': 'corn',
};

String normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _stem(String word) {
  final mapped = _synonyms[word];
  if (mapped != null) {
    return mapped;
  }
  if (word.endsWith('ies') && word.length > 4) {
    return '${word.substring(0, word.length - 3)}y';
  }
  if (word.endsWith('oes') && word.length > 4) {
    return word.substring(0, word.length - 2);
  }
  if (word.endsWith('es') && word.length > 4 && !word.endsWith('sses')) {
    return word.substring(0, word.length - 2);
  }
  if (word.endsWith('s') && word.length > 3 && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

bool _tokenFits(String haystack, String word) {
  if (word.length < 2) {
    return true;
  }
  final stem = _stem(word);
  if (haystack.contains(word) || haystack.contains(stem)) {
    return true;
  }
  if (stem.length < 3) {
    return false;
  }
  final tokens = haystack.split(' ');
  return tokens.any(
    (token) =>
        token.startsWith(stem) ||
        stem.startsWith(token) && token.length >= 4,
  );
}

String plantSearchHaystack(Plant plant) {
  return normalizeSearchText([
    plant.name,
    plant.displayName,
    plant.category,
    plant.brand ?? '',
    plant.packetExtract ?? '',
    plant.searchTags ?? '',
  ].join(' '));
}

int plantMatchScore(Plant plant, String query) {
  final q = normalizeSearchText(query);
  if (q.isEmpty) {
    return 1;
  }
  final haystack = plantSearchHaystack(plant);
  final name = normalizeSearchText(plant.name);
  final display = normalizeSearchText(plant.displayName);
  final brand = normalizeSearchText(plant.brand ?? '');
  if (display == q || name == q) {
    return 100;
  }
  if (display.startsWith(q) || name.startsWith(q)) {
    return 80;
  }
  final words = q.split(' ').where((word) => word.length > 1).toList();
  if (words.isEmpty) {
    return haystack.contains(q) ? 40 : 0;
  }
  final matched = [
    for (final word in words)
      if (_tokenFits(haystack, word)) word,
  ];
  if (matched.isEmpty) {
    return 0;
  }
  // Brand + crop ("burpee cucumber") should beat a generic cucumber.
  if (matched.length == words.length) {
    final brandHit = brand.isNotEmpty &&
        words.any((word) => _tokenFits(brand, word));
    return brandHit ? 92 : 70;
  }
  if (matched.length >= (words.length / 2).ceil()) {
    return 35;
  }
  return 0;
}

bool plantMatchesQuery(Plant plant, String query) {
  return plantMatchScore(plant, query) > 0;
}

List<Plant> rankCatalogPlants(String query) {
  final scored = [
    for (final plant in catalogPlants)
      (plant: plant, score: plantMatchScore(plant, query)),
  ].where((item) => item.score > 0).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return [for (final item in scored) item.plant];
}
