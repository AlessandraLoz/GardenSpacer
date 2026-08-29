import 'dart:math' as math;

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
  final count = (sqFt * plant.perSquareFoot!).floor();
  final grid = squareFootGrid(count, bedLengthIn, bedWidthIn);
  return PlantCountResult(count: count, rows: grid.$1, perRow: grid.$2);
}

(int, int) squareFootGrid(int count, double bedLengthIn, double bedWidthIn) {
  if (count <= 0) {
    return (0, 0);
  }
  final aspect = bedLengthIn <= 0 || bedWidthIn <= 0
      ? 1.0
      : bedLengthIn / bedWidthIn;
  var cols = math.sqrt(count * aspect).round().clamp(1, count);
  var rows = (count / cols).ceil();
  if (rows < 1) {
    rows = 1;
  }
  return (rows, cols);
}
