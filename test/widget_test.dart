import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_spacer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows saved-beds empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenSpacerApp());
    await tester.pump();

    expect(find.text('GardenSpacer'), findsOneWidget);
    expect(find.text('Your garden starts here'), findsOneWidget);
    expect(find.text('New bed'), findsOneWidget);
  });
}
