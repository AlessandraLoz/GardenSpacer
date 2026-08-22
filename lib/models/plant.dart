enum SpacingMethod { row, squareFoot }

class Plant {
  final String name;
  final String category; // herb, vegetable, fruit
  final SpacingMethod method;

  // Row method
  final double? inRowInches;
  final double? betweenRowInches;

  // Square-foot method
  final int? perSquareFoot;

  final String? brand;
  final String? packetExtract;

  Plant({
    required this.name,
    required this.category,
    required this.method,
    this.inRowInches,
    this.betweenRowInches,
    this.perSquareFoot,
    this.brand,
    this.packetExtract,
  });

  String get displayName {
    if (brand == null || brand!.isEmpty) {
      return name;
    }
    return '$brand · $name';
  }
}
