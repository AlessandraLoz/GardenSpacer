import 'package:flutter/material.dart';

import '../logic/unit_conversion.dart';

class UnitButtons extends StatelessWidget {
  final BedUnit value;
  final ValueChanged<BedUnit> onChanged;

  const UnitButtons({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final unit in BedUnit.values)
          Tooltip(
            message: bedUnitLabel(unit),
            child: FilterChip(
              selected: value == unit,
              showCheckmark: false,
              label: Text(bedUnitShort(unit)),
              onSelected: (_) => onChanged(unit),
            ),
          ),
      ],
    );
  }
}
