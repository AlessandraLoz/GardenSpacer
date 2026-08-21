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

  Plant({
    required this.name,
    required this.category,
    required this.method,
    this.inRowInches,
    this.betweenRowInches,
    this.perSquareFoot,
  });
}
