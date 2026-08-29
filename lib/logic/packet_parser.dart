import '../models/plant.dart';
import 'unit_conversion.dart';

class PacketParseResult {
  final Plant plant;
  final String explanation;

  const PacketParseResult({required this.plant, required this.explanation});
}

/// Pulls row spacing or square-foot density from typical seed-packet wording.
PacketParseResult? parseSeedPacketText(
  String raw, {
  String? name,
  String? brand,
}) {
  final text = cleanPacketText(raw);
  if (text.isEmpty) {
    return null;
  }

  final perSqFt = _perSquareFoot(text);
  if (perSqFt != null) {
    final explanation = '$perSqFt plants per square foot';
    return PacketParseResult(
      plant: Plant(
        name: name ?? 'Custom packet',
        category: 'vegetable',
        method: SpacingMethod.squareFoot,
        perSquareFoot: perSqFt,
        brand: brand,
        packetExtract: explanation,
      ),
      explanation: explanation,
    );
  }

  final pair = _inRowAndBetween(text);
  var inRow = pair.$1 ?? _labeledInRowInches(text) ?? _inRowInches(text);
  var betweenRow =
      pair.$2 ?? _labeledBetweenRowInches(text) ?? _betweenRowInches(text);

  if (inRow != null && inRow < 2 && betweenRow != null && betweenRow >= 12) {
    inRow = null;
  }

  if (inRow != null && betweenRow == null) {
    betweenRow = inRow;
  }

  if (inRow != null && betweenRow != null && inRow > 0 && betweenRow > 0) {
    final explanation =
        '${_prettyInches(inRow)} in the row, ${_prettyInches(betweenRow)} between rows';
    return PacketParseResult(
      plant: Plant(
        name: name ?? 'Custom packet',
        category: 'vegetable',
        method: SpacingMethod.row,
        inRowInches: inRow,
        betweenRowInches: betweenRow,
        brand: brand,
        packetExtract: explanation,
      ),
      explanation: explanation,
    );
  }

  return null;
}

String cleanPacketText(String raw) {
  return raw
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#x27;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAllMapped(RegExp(r'(\d)\?(?!\d)'), (m) => '${m[1]}"')
      .replaceAll('″', '"')
      .replaceAll('′', "'")
      .replaceAll('×', 'x')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}

double? _labeledInRowInches(String text) {
  final match = RegExp(
    r'(?:plant|plants?)\s+spacing\s*:?\s*' +
        _amountPattern +
        r'\s*' +
        _unitPattern,
  ).firstMatch(text);
  if (match == null) {
    final seed = RegExp(
      r'seed\s+spacing\s*:?\s*' + _amountPattern + r'\s*' + _unitPattern,
    ).firstMatch(text);
    if (seed == null) {
      return null;
    }
    final inches = _rangeToInches(seed);
    return inches >= 2 ? inches : null;
  }
  return _rangeToInches(match);
}

double? _labeledBetweenRowInches(String text) {
  final match = RegExp(
    r'row\s+spacing\s*:?\s*' + _amountPattern + r'\s*' + _unitPattern,
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  return _rangeToInches(match);
}

int? _perSquareFoot(String text) {
  final match = RegExp(
    r'(\d+)\s*(?:plants?\s+)?(?:per|/)\s*(?:sq\.?\s*ft\.?|sqft|square\s+feet|square\s+foot)',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

(double?, double?) _inRowAndBetween(String text) {
  final match = RegExp(
    _amountPattern +
        r'\s*(?:x|by)\s*' +
        _amountPattern2 +
        r'\s*' +
        _unitPattern,
  ).firstMatch(text);
  if (match == null) {
    return (null, null);
  }
  final unit = match.namedGroup('unit') ?? 'in';
  final first = amountToInches(_parseNumber(match.namedGroup('amount')!), unit);
  final second = amountToInches(_parseNumber(match.namedGroup('b')!), unit);
  return (first, second);
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
      r'(?:sow|plant|space|spaced|spacing|every)\s+(?:plants?\s+)?' +
          _amountPattern +
          r'\s*' +
          _unitPattern +
          r'(?:\s*apart)?',
    ),
    RegExp(
      r'set\s+plants?\s+' + _amountPattern + r'\s*' + _unitPattern + r'\s*apart',
    ),
    RegExp(
      r'plants?\s+' + _amountPattern + r'\s*' + _unitPattern + r'\s*apart',
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
    r'(?<amount>\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)(?:\s*(?:[-–]|to|or)\s*(?<amount2>\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?))?';
const _amountPattern2 =
    r'(?<b>\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)';
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
