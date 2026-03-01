import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/main.dart';

void main() {
  testWidgets('Today screen renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Andrew'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Save rating'), findsOneWidget);
  });
}
