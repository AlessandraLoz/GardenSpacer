enum BedUnit { inches, feet, centimeters, millimeters, meters }

double toInches(double value, BedUnit unit) {
  switch (unit) {
    case BedUnit.inches:
      return value;
    case BedUnit.feet:
      return value * 12;
    case BedUnit.centimeters:
      return value / 2.54;
    case BedUnit.millimeters:
      return value / 25.4;
    case BedUnit.meters:
      return value * (100 / 2.54);
  }
}

double amountToInches(double value, String unit) {
  switch (unit.toLowerCase()) {
    case 'in':
    case 'inch':
    case 'inches':
    case '"':
      return value;
    case 'ft':
    case 'foot':
    case 'feet':
    case "'":
      return value * 12;
    case 'cm':
    case 'centimeter':
    case 'centimeters':
      return value / 2.54;
    case 'mm':
    case 'millimeter':
    case 'millimeters':
      return value / 25.4;
    case 'm':
    case 'meter':
    case 'meters':
      return value * (100 / 2.54);
    default:
      return value;
  }
}

String bedUnitLabel(BedUnit unit) {
  switch (unit) {
    case BedUnit.inches:
      return 'inches';
    case BedUnit.feet:
      return 'feet';
    case BedUnit.centimeters:
      return 'centimeters';
    case BedUnit.millimeters:
      return 'millimeters';
    case BedUnit.meters:
      return 'meters';
  }
}

String bedUnitShort(BedUnit unit) {
  switch (unit) {
    case BedUnit.inches:
      return 'in';
    case BedUnit.feet:
      return 'ft';
    case BedUnit.centimeters:
      return 'cm';
    case BedUnit.millimeters:
      return 'mm';
    case BedUnit.meters:
      return 'm';
  }
}
