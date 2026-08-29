import 'package:flutter/material.dart';

import '../theme/appearance.dart';

class AppearanceScope extends InheritedWidget {
  final Appearance appearance;
  final ValueChanged<Appearance> onChanged;

  const AppearanceScope({
    super.key,
    required this.appearance,
    required this.onChanged,
    required super.child,
  });

  static AppearanceScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppearanceScope>();
    assert(scope != null, 'AppearanceScope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppearanceScope oldWidget) {
    return appearance.palette != oldWidget.appearance.palette ||
        appearance.layout != oldWidget.appearance.layout;
  }
}
