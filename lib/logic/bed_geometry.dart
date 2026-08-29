import '../models/saved_bed.dart';
import 'unit_conversion.dart';

const bedGeomEpsilon = 0.05;
const minSubBedInches = 1.0;

class InchRect {
  final double x;
  final double y;
  final double length;
  final double width;

  const InchRect({
    required this.x,
    required this.y,
    required this.length,
    required this.width,
  });

  double get right => x + length;
  double get bottom => y + width;

  InchRect copyWith({
    double? x,
    double? y,
    double? length,
    double? width,
  }) {
    return InchRect(
      x: x ?? this.x,
      y: y ?? this.y,
      length: length ?? this.length,
      width: width ?? this.width,
    );
  }
}

bool rectsOverlap(InchRect a, InchRect b) {
  return a.x < b.right - bedGeomEpsilon &&
      a.right > b.x + bedGeomEpsilon &&
      a.y < b.bottom - bedGeomEpsilon &&
      a.bottom > b.y + bedGeomEpsilon;
}

bool rectWithinMaster(InchRect rect, double masterLengthIn, double masterWidthIn) {
  return rect.x >= -bedGeomEpsilon &&
      rect.y >= -bedGeomEpsilon &&
      rect.right <= masterLengthIn + bedGeomEpsilon &&
      rect.bottom <= masterWidthIn + bedGeomEpsilon &&
      rect.length >= minSubBedInches - bedGeomEpsilon &&
      rect.width >= minSubBedInches - bedGeomEpsilon;
}

bool placementAllowed({
  required InchRect candidate,
  required double masterLengthIn,
  required double masterWidthIn,
  required List<InchRect> others,
}) {
  if (!rectWithinMaster(candidate, masterLengthIn, masterWidthIn)) {
    return false;
  }
  for (final other in others) {
    if (rectsOverlap(candidate, other)) {
      return false;
    }
  }
  return true;
}

InchRect defaultRectForIndex({
  required int index,
  required int count,
  required double masterLengthIn,
  required double masterWidthIn,
}) {
  if (count <= 1) {
    return InchRect(
      x: 0,
      y: 0,
      length: masterLengthIn,
      width: masterWidthIn,
    );
  }
  final strip = masterWidthIn / count;
  return InchRect(
    x: 0,
    y: strip * index,
    length: masterLengthIn,
    width: strip,
  );
}

InchRect plantingToInchRect({
  required SavedPlanting planting,
  required BedUnit masterUnit,
  required double masterLengthIn,
  required double masterWidthIn,
  required int index,
  required int count,
}) {
  if (!planting.hasPlacement) {
    return defaultRectForIndex(
      index: index,
      count: count,
      masterLengthIn: masterLengthIn,
      masterWidthIn: masterWidthIn,
    );
  }
  final sizeUnit = bedUnitFromName(planting.sizeUnit ?? masterUnit.name);
  final x = toInches(double.tryParse(planting.x!.trim()) ?? 0, masterUnit);
  final y = toInches(double.tryParse(planting.y!.trim()) ?? 0, masterUnit);
  final length = toInches(
    double.tryParse(planting.length!.trim()) ?? 0,
    sizeUnit,
  );
  final width = toInches(
    double.tryParse(planting.width!.trim()) ?? 0,
    sizeUnit,
  );
  return InchRect(x: x, y: y, length: length, width: width);
}

SavedPlanting plantingWithRect(
  SavedPlanting planting,
  InchRect rect,
  BedUnit masterUnit,
) {
  final sizeUnit = bedUnitFromName(planting.sizeUnit ?? masterUnit.name);
  return planting.copyWith(
    x: formatAmount(fromInches(rect.x, masterUnit)),
    y: formatAmount(fromInches(rect.y, masterUnit)),
    length: formatAmount(fromInches(rect.length, sizeUnit)),
    width: formatAmount(fromInches(rect.width, sizeUnit)),
    sizeUnit: sizeUnit.name,
  );
}

List<InchRect> plantingRectsInches({
  required List<SavedPlanting> plantings,
  required BedUnit masterUnit,
  required double masterLengthIn,
  required double masterWidthIn,
}) {
  return [
    for (var i = 0; i < plantings.length; i++)
      plantingToInchRect(
        planting: plantings[i],
        masterUnit: masterUnit,
        masterLengthIn: masterLengthIn,
        masterWidthIn: masterWidthIn,
        index: i,
        count: plantings.length,
      ),
  ];
}

InchRect? tryPlaceRect({
  required double length,
  required double width,
  required double masterLengthIn,
  required double masterWidthIn,
  required List<InchRect> occupied,
}) {
  var w = length.clamp(minSubBedInches, masterLengthIn);
  var h = width.clamp(minSubBedInches, masterWidthIn);
  const step = 2.0;
  for (var y = 0.0; y + h <= masterWidthIn + bedGeomEpsilon; y += step) {
    for (var x = 0.0; x + w <= masterLengthIn + bedGeomEpsilon; x += step) {
      final candidate = InchRect(x: x, y: y, length: w, width: h);
      if (placementAllowed(
        candidate: candidate,
        masterLengthIn: masterLengthIn,
        masterWidthIn: masterWidthIn,
        others: occupied,
      )) {
        return candidate;
      }
    }
  }
  w = (masterLengthIn / 2).clamp(minSubBedInches, masterLengthIn);
  h = (masterWidthIn / 2).clamp(minSubBedInches, masterWidthIn);
  for (var y = 0.0; y + h <= masterWidthIn + bedGeomEpsilon; y += step) {
    for (var x = 0.0; x + w <= masterLengthIn + bedGeomEpsilon; x += step) {
      final candidate = InchRect(x: x, y: y, length: w, width: h);
      if (placementAllowed(
        candidate: candidate,
        masterLengthIn: masterLengthIn,
        masterWidthIn: masterWidthIn,
        others: occupied,
      )) {
        return candidate;
      }
    }
  }
  return null;
}

SavedPlanting placeNewPlanting({
  required SavedPlanting planting,
  required List<SavedPlanting> existing,
  required BedUnit masterUnit,
  required double masterLengthIn,
  required double masterWidthIn,
}) {
  final occupied = plantingRectsInches(
    plantings: existing,
    masterUnit: masterUnit,
    masterLengthIn: masterLengthIn,
    masterWidthIn: masterWidthIn,
  );
  final sizeUnit = bedUnitFromName(planting.sizeUnit ?? masterUnit.name);
  final wantedLength = planting.hasPlacement
      ? toInches(double.tryParse(planting.length!.trim()) ?? 0, sizeUnit)
      : (existing.isEmpty ? masterLengthIn : masterLengthIn / 2);
  final wantedWidth = planting.hasPlacement
      ? toInches(double.tryParse(planting.width!.trim()) ?? 0, sizeUnit)
      : (existing.isEmpty ? masterWidthIn : masterWidthIn / 2);
  final placed = tryPlaceRect(
        length: wantedLength <= 0 ? masterLengthIn / 2 : wantedLength,
        width: wantedWidth <= 0 ? masterWidthIn / 2 : wantedWidth,
        masterLengthIn: masterLengthIn,
        masterWidthIn: masterWidthIn,
        occupied: occupied,
      ) ??
      defaultRectForIndex(
        index: existing.length,
        count: existing.length + 1,
        masterLengthIn: masterLengthIn,
        masterWidthIn: masterWidthIn,
      );
  return plantingWithRect(planting, placed, masterUnit);
}

List<SavedPlanting> packPlantingsIntoMaster({
  required List<SavedPlanting> plantings,
  required BedUnit masterUnit,
  required double masterLengthIn,
  required double masterWidthIn,
  required List<InchRect> preferredSizes,
}) {
  final packed = <SavedPlanting>[];
  final occupied = <InchRect>[];
  var failed = false;
  for (var i = 0; i < plantings.length; i++) {
    final size = preferredSizes[i];
    final rect = tryPlaceRect(
      length: size.length,
      width: size.width,
      masterLengthIn: masterLengthIn,
      masterWidthIn: masterWidthIn,
      occupied: occupied,
    );
    if (rect == null) {
      failed = true;
      break;
    }
    occupied.add(rect);
    packed.add(plantingWithRect(plantings[i], rect, masterUnit));
  }
  if (!failed) {
    return packed;
  }
  return [
    for (var i = 0; i < plantings.length; i++)
      plantingWithRect(
        plantings[i],
        defaultRectForIndex(
          index: i,
          count: plantings.length,
          masterLengthIn: masterLengthIn,
          masterWidthIn: masterWidthIn,
        ),
        masterUnit,
      ),
  ];
}

List<SavedPlanting> clampPlantingsToMaster({
  required List<SavedPlanting> plantings,
  required BedUnit masterUnit,
  required double masterLengthIn,
  required double masterWidthIn,
}) {
  final next = [...plantings];
  for (var i = 0; i < next.length; i++) {
    var rect = plantingToInchRect(
      planting: next[i],
      masterUnit: masterUnit,
      masterLengthIn: masterLengthIn,
      masterWidthIn: masterWidthIn,
      index: i,
      count: next.length,
    );
    final length =
        rect.length.clamp(minSubBedInches, masterLengthIn).toDouble();
    final width = rect.width.clamp(minSubBedInches, masterWidthIn).toDouble();
    final x = rect.x.clamp(0, masterLengthIn - length).toDouble();
    final y = rect.y.clamp(0, masterWidthIn - width).toDouble();
    var candidate = InchRect(x: x, y: y, length: length, width: width);
    final others = [
      for (var j = 0; j < next.length; j++)
        if (j != i)
          plantingToInchRect(
            planting: next[j],
            masterUnit: masterUnit,
            masterLengthIn: masterLengthIn,
            masterWidthIn: masterWidthIn,
            index: j,
            count: next.length,
          ),
    ];
    if (!placementAllowed(
      candidate: candidate,
      masterLengthIn: masterLengthIn,
      masterWidthIn: masterWidthIn,
      others: others,
    )) {
      candidate = tryPlaceRect(
            length: length,
            width: width,
            masterLengthIn: masterLengthIn,
            masterWidthIn: masterWidthIn,
            occupied: others,
          ) ??
          candidate;
    }
    next[i] = plantingWithRect(next[i], candidate, masterUnit);
  }
  return next;
}
