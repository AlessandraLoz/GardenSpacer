import '../models/plant.dart';

final List<Plant> starterPlants = [
  Plant(name: "Tomato (indeterminate)", category: "vegetable", method: SpacingMethod.row, inRowInches: 30, betweenRowInches: 42),
  Plant(name: "Bush Bean", category: "vegetable", method: SpacingMethod.row, inRowInches: 4, betweenRowInches: 20),
  Plant(name: "Broccoli", category: "vegetable", method: SpacingMethod.squareFoot, perSquareFoot: 1),
  Plant(name: "Lettuce (leaf)", category: "vegetable", method: SpacingMethod.squareFoot, perSquareFoot: 4),
  Plant(name: "Carrot", category: "vegetable", method: SpacingMethod.squareFoot, perSquareFoot: 16),
  Plant(name: "Basil", category: "herb", method: SpacingMethod.squareFoot, perSquareFoot: 4),
  Plant(name: "Cucumber (trellised)", category: "vegetable", method: SpacingMethod.row, inRowInches: 12, betweenRowInches: 42),
  Plant(name: "Pepper", category: "vegetable", method: SpacingMethod.row, inRowInches: 18, betweenRowInches: 30),
];
