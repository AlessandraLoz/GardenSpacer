import '../models/saved_bed.dart';

enum GardenKindFilter { all, single, master }

class GardenListSection {
  final String title;
  final List<SavedBed> beds;

  const GardenListSection({
    required this.title,
    required this.beds,
  });
}

List<GardenListSection> gardenListSections(
  List<SavedBed> beds,
  GardenKindFilter filter,
) {
  final masters = [for (final bed in beds) if (bed.isMaster) bed];
  final singles = [for (final bed in beds) if (!bed.isMaster) bed];

  switch (filter) {
    case GardenKindFilter.all:
      return [
        if (masters.isNotEmpty)
          GardenListSection(title: 'Master beds', beds: masters),
        if (singles.isNotEmpty)
          GardenListSection(title: 'Single-plant beds', beds: singles),
      ];
    case GardenKindFilter.master:
      return [
        if (masters.isNotEmpty)
          GardenListSection(title: 'Master beds', beds: masters),
      ];
    case GardenKindFilter.single:
      return [
        if (singles.isNotEmpty)
          GardenListSection(title: 'Single-plant beds', beds: singles),
      ];
  }
}
