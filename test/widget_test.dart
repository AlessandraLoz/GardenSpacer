import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_spacer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows calculate controls', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenSpacerApp());
    await tester.pump();

    expect(find.text('GardenSpacer'), findsOneWidget);
    expect(find.text('Bed name'), findsOneWidget);
    expect(find.text('Bed length (inches)'), findsOneWidget);
    expect(find.text('Bed width (inches)'), findsOneWidget);
    expect(find.text('Calculate and save'), findsOneWidget);
  });
}
