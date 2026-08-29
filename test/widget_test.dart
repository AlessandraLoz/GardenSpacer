import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_spacer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows saved-beds empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenSpacerApp());
    await tester.pump();

    expect(find.text('GardenSpacer'), findsOneWidget);
    expect(find.text('Your beds will show up here'), findsOneWidget);
    expect(find.text('New bed'), findsOneWidget);
  });
}
