import 'package:flutter_test/flutter_test.dart';

import 'package:garden_spacer/main.dart';

void main() {
  testWidgets('Home screen shows calculate controls', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenSpacerApp());

    expect(find.text('GardenSpacer'), findsOneWidget);
    expect(find.text('Bed length (inches)'), findsOneWidget);
    expect(find.text('Bed width (inches)'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });
}
