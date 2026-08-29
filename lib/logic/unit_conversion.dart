enum BedUnit { inches, feet, centimeters, millimeters, meters }

BedUnit bedUnitFromName(String? name) {
  return BedUnit.values.firstWhere(
    (value) => value.name == name,
    orElse: () => BedUnit.inches,
  );
}

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

double fromInches(double inches, BedUnit unit) {
  switch (unit) {
    case BedUnit.inches:
      return inches;
    case BedUnit.feet:
      return inches / 12;
    case BedUnit.centimeters:
      return inches * 2.54;
    case BedUnit.millimeters:
      return inches * 25.4;
    case BedUnit.meters:
      return inches * 2.54 / 100;
  }
}

String formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  var text = value.toStringAsFixed(3);
  while (text.contains('.') && text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
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
