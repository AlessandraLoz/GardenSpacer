import '../models/plant.dart';

class PlantCountResult {
  final int count;
  final int? rows;
  final int? perRow;

  const PlantCountResult({
    required this.count,
    this.rows,
    this.perRow,
  });
}

/// How many plants fit along one edge: first plant, then another every [spacing]
/// inches, including a plant on the far side when it still sits in the bed.
int plantsAlong(double lengthIn, double spacingIn) {
  if (lengthIn <= 0 || spacingIn <= 0) {
    return 0;
  }
  return (lengthIn / spacingIn).floor() + 1;
}

int calculatePlantCount(Plant plant, double bedLengthIn, double bedWidthIn) {
  return calculatePlantLayout(plant, bedLengthIn, bedWidthIn).count;
}

PlantCountResult calculatePlantLayout(
  Plant plant,
  double bedLengthIn,
  double bedWidthIn,
) {
  if (plant.method == SpacingMethod.row) {
    final inRow = plant.inRowInches!;
    final betweenRow = plant.betweenRowInches!;

    final rowsA = plantsAlong(bedWidthIn, betweenRow);
    final perRowA = plantsAlong(bedLengthIn, inRow);
    final countA = rowsA * perRowA;

    final rowsB = plantsAlong(bedLengthIn, betweenRow);
    final perRowB = plantsAlong(bedWidthIn, inRow);
    final countB = rowsB * perRowB;

    if (countB > countA) {
      return PlantCountResult(count: countB, rows: rowsB, perRow: perRowB);
    }
    return PlantCountResult(count: countA, rows: rowsA, perRow: perRowA);
  }

  final sqFt = (bedLengthIn * bedWidthIn) / 144;
  return PlantCountResult(count: (sqFt * plant.perSquareFoot!).floor());
}
