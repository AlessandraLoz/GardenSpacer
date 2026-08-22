class SavedBed {
  final String name;
  final String length;
  final String width;
  final String unit;
  final String? plantDisplayName;
  final String packetText;

  const SavedBed({
    required this.name,
    required this.length,
    required this.width,
    required this.unit,
    this.plantDisplayName,
    this.packetText = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'length': length,
        'width': width,
        'unit': unit,
        'plantDisplayName': plantDisplayName,
        'packetText': packetText,
      };

  factory SavedBed.fromJson(Map<String, dynamic> json) {
    return SavedBed(
      name: json['name'] as String,
      length: json['length'] as String,
      width: json['width'] as String,
      unit: json['unit'] as String,
      plantDisplayName: json['plantDisplayName'] as String?,
      packetText: (json['packetText'] as String?) ?? '',
    );
  }
}
