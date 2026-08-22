import '../models/plant.dart';
import 'unit_conversion.dart';

class PacketParseResult {
  final Plant plant;
  final String explanation;

  const PacketParseResult({required this.plant, required this.explanation});
}

/// Pulls row spacing or square-foot density from typical seed-packet wording.
PacketParseResult? parseSeedPacketText(String raw) {
  final text = raw
      .toLowerCase()
      .replaceAll('″', '"')
      .replaceAll('′', "'")
      .replaceAll('×', 'x')
      .replaceAll(RegExp(r'\s+'), ' ');

  if (text.trim().isEmpty) {
    return null;
  }

  final perSqFt = _perSquareFoot(text);
  if (perSqFt != null) {
    return PacketParseResult(
      plant: Plant(
        name: 'Custom packet',
        category: 'vegetable',
        method: SpacingMethod.squareFoot,
        perSquareFoot: perSqFt,
      ),
      explanation: '$perSqFt plants per square foot',
    );
  }

  final inRow = _inRowInches(text);
  final betweenRow = _betweenRowInches(text);
  if (inRow != null && betweenRow != null && inRow > 0 && betweenRow > 0) {
    return PacketParseResult(
      plant: Plant(
        name: 'Custom packet',
        category: 'vegetable',
        method: SpacingMethod.row,
        inRowInches: inRow,
        betweenRowInches: betweenRow,
      ),
      explanation:
          '${_prettyInches(inRow)} in the row, ${_prettyInches(betweenRow)} between rows',
    );
  }

  return null;
}

int? _perSquareFoot(String text) {
  final match = RegExp(
    r'(\d+)\s*(?:plants?\s+)?(?:per|/)\s*(?:sq\.?\s*ft\.?|square\s+feet|square\s+foot)',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

double? _inRowInches(String text) {
  final patterns = [
    RegExp(
      r'thin(?:ned)?(?:\s+plants?)?\s+to\s+' +
          _amountPattern +
          r'(?:\s*' +
          _unitPattern +
          r')?',
    ),
    RegExp(
      r'set\s+plants?\s+' + _amountPattern + r'\s*' + _unitPattern + r'\s*apart',
    ),
    RegExp(
      r'plants?\s+' + _amountPattern + r'\s*' + _unitPattern + r'\s*apart',
    ),
    RegExp(
      r'(?:space|spaced|spacing)\s+(?:plants?\s+)?' +
          _amountPattern +
          r'\s*' +
          _unitPattern,
    ),
    RegExp(
      _amountPattern +
          r'\s*' +
          _unitPattern +
          r'\s*apart(?!\s+(?:in\s+)?rows?)',
    ),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return _rangeToInches(match);
    }
  }
  return null;
}

double? _betweenRowInches(String text) {
  final patterns = [
    RegExp(
      r'(?:in\s+)?rows?\s+(?:of\s+|apart\s+|at\s+)?' +
          _amountPattern +
          r'\s*' +
          _unitPattern,
    ),
    RegExp(
      _amountPattern +
          r'\s*' +
          _unitPattern +
          r'\s*(?:apart\s+)?(?:between\s+)?(?:the\s+)?rows?',
    ),
    RegExp(
      r'row\s+spacing\s+' + _amountPattern + r'\s*' + _unitPattern,
    ),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return _rangeToInches(match);
    }
  }
  return null;
}

const _amountPattern =
    r'(?<amount>\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)(?:\s*[-–to]+\s*(?<amount2>\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?))?';
const _unitPattern =
    r'(?<unit>inches|inch|in|feet|foot|ft|centimeters|centimeter|cm|millimeters|millimeter|mm|meters|meter|m|"|\x27)';

double _rangeToInches(RegExpMatch match) {
  final first = _parseNumber(match.namedGroup('amount')!);
  final secondRaw = match.namedGroup('amount2');
  final unit = match.namedGroup('unit') ?? 'in';
  final firstIn = amountToInches(first, unit);
  if (secondRaw == null) {
    return firstIn;
  }
  final secondIn = amountToInches(_parseNumber(secondRaw), unit);
  return firstIn > secondIn ? firstIn : secondIn;
}

double _parseNumber(String raw) {
  final text = raw.trim();
  final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(text);
  if (mixed != null) {
    return int.parse(mixed.group(1)!) +
        int.parse(mixed.group(2)!) / int.parse(mixed.group(3)!);
  }
  final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(text);
  if (fraction != null) {
    return int.parse(fraction.group(1)!) / int.parse(fraction.group(2)!);
  }
  return double.parse(text);
}

String _prettyInches(double inches) {
  if (inches == inches.roundToDouble()) {
    return '${inches.toStringAsFixed(0)} in';
  }
  return '${inches.toStringAsFixed(1)} in';
}
