import '../models/plant.dart';

int calculatePlantCount(Plant plant, double bedLengthIn, double bedWidthIn) {
  if (plant.method == SpacingMethod.row) {
    int rows = (bedWidthIn / plant.betweenRowInches!).floor();
    int perRow = (bedLengthIn / plant.inRowInches!).floor();
    return rows * perRow;
  } else {
    double sqFt = (bedLengthIn * bedWidthIn) / 144;
    return (sqFt * plant.perSquareFoot!).floor();
  }
}
