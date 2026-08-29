class SavedPlanting {
  final String? name;
  final String method;
  final String? inRow;
  final String? betweenRow;
  final String? perSquareFoot;
  final String spacingUnit;
  final String? plantDisplayName;
  final String packetText;
  final String? x;
  final String? y;
  final String? length;
  final String? width;
  final String? sizeUnit;

  const SavedPlanting({
    this.name,
    this.method = 'row',
    this.inRow,
    this.betweenRow,
    this.perSquareFoot,
    this.spacingUnit = 'inches',
    this.plantDisplayName,
    this.packetText = '',
    this.x,
    this.y,
    this.length,
    this.width,
    this.sizeUnit,
  });

  String get label =>
      (name ?? plantDisplayName)?.trim().isNotEmpty == true
          ? (name ?? plantDisplayName)!.trim()
          : 'Plant';

  bool get hasExplicitSpacing {
    if (method == 'squareFoot') {
      return (perSquareFoot ?? '').trim().isNotEmpty;
    }
    return (inRow ?? '').trim().isNotEmpty &&
        (betweenRow ?? '').trim().isNotEmpty;
  }

  bool get hasPlacement =>
      (x ?? '').trim().isNotEmpty &&
      (y ?? '').trim().isNotEmpty &&
      (length ?? '').trim().isNotEmpty &&
      (width ?? '').trim().isNotEmpty;

  SavedPlanting copyWith({
    String? name,
    String? method,
    String? inRow,
    String? betweenRow,
    String? perSquareFoot,
    String? spacingUnit,
    String? plantDisplayName,
    String? packetText,
    String? x,
    String? y,
    String? length,
    String? width,
    String? sizeUnit,
  }) {
    return SavedPlanting(
      name: name ?? this.name,
      method: method ?? this.method,
      inRow: inRow ?? this.inRow,
      betweenRow: betweenRow ?? this.betweenRow,
      perSquareFoot: perSquareFoot ?? this.perSquareFoot,
      spacingUnit: spacingUnit ?? this.spacingUnit,
      plantDisplayName: plantDisplayName ?? this.plantDisplayName,
      packetText: packetText ?? this.packetText,
      x: x ?? this.x,
      y: y ?? this.y,
      length: length ?? this.length,
      width: width ?? this.width,
      sizeUnit: sizeUnit ?? this.sizeUnit,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name ?? plantDisplayName,
        'method': method,
        'inRow': inRow,
        'betweenRow': betweenRow,
        'perSquareFoot': perSquareFoot,
        'spacingUnit': spacingUnit,
        'plantDisplayName': plantDisplayName ?? name,
        'packetText': packetText,
        'x': x,
        'y': y,
        'length': length,
        'width': width,
        'sizeUnit': sizeUnit,
      };

  factory SavedPlanting.fromJson(Map<String, dynamic> json) {
    return SavedPlanting(
      name: json['name'] as String?,
      method: (json['method'] as String?) ?? 'row',
      inRow: json['inRow'] as String?,
      betweenRow: json['betweenRow'] as String?,
      perSquareFoot: json['perSquareFoot']?.toString(),
      spacingUnit: (json['spacingUnit'] as String?) ?? 'inches',
      plantDisplayName: json['plantDisplayName'] as String?,
      packetText: (json['packetText'] as String?) ?? '',
      x: json['x']?.toString(),
      y: json['y']?.toString(),
      length: json['length']?.toString(),
      width: json['width']?.toString(),
      sizeUnit: json['sizeUnit'] as String?,
    );
  }
}

class SavedBed {
  final String name;
  final String length;
  final String width;
  final String unit;
  final String icon;
  final String? plantDisplayName;
  final String packetText;
  final List<SavedPlanting> plantings;

  const SavedBed({
    required this.name,
    required this.length,
    required this.width,
    required this.unit,
    this.icon = 'eco',
    this.plantDisplayName,
    this.packetText = '',
    this.plantings = const [],
  });

  bool get isMaster => allPlantings.length > 1;

  List<SavedPlanting> get allPlantings {
    if (plantings.isNotEmpty) {
      return plantings;
    }
    if (plantDisplayName != null || packetText.trim().isNotEmpty) {
      return [
        SavedPlanting(
          plantDisplayName: plantDisplayName,
          packetText: packetText,
        ),
      ];
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'length': length,
        'width': width,
        'unit': unit,
        'icon': icon,
        'plantings': [for (final planting in allPlantings) planting.toJson()],
      };

  factory SavedBed.fromJson(Map<String, dynamic> json) {
    final rawPlantings = json['plantings'];
    final plantings = <SavedPlanting>[];
    if (rawPlantings is List) {
      for (final item in rawPlantings) {
        plantings.add(SavedPlanting.fromJson(item as Map<String, dynamic>));
      }
    }
    return SavedBed(
      name: json['name'] as String,
      length: json['length'] as String,
      width: json['width'] as String,
      unit: json['unit'] as String,
      icon: (json['icon'] as String?) ?? 'eco',
      plantDisplayName: json['plantDisplayName'] as String?,
      packetText: (json['packetText'] as String?) ?? '',
      plantings: plantings,
    );
  }
}
