import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/app/app_root.dart';
import 'package:perfect_day/main.dart';

void main() {
  testWidgets('Home screen renders quick capture actions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppRoot.termsAcceptedKey: true,
      AppRoot.privacyAcceptedKey: true,
    });
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Quick assessment'), findsOneWidget);
    expect(find.text('Micro-note'), findsOneWidget);
    expect(find.text('Save quick assessment'), findsOneWidget);
  });

  testWidgets('Consent screen shows when not accepted', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    expect(find.text('Consent'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Settings tab opens source management', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppRoot.termsAcceptedKey: true,
      AppRoot.privacyAcceptedKey: true,
    });
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Connected sources'), findsOneWidget);
    expect(find.text('Historical import'), findsOneWidget);
    expect(find.text('Auto-sync on app open'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
  });

  testWidgets('Trends tab opens with range selector', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppRoot.termsAcceptedKey: true,
      AppRoot.privacyAcceptedKey: true,
    });
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();

    expect(find.text('Trends'), findsWidgets);
    expect(find.text('Week'), findsWidgets);
    expect(find.text('Month'), findsWidgets);
    expect(find.text('Year'), findsWidgets);
  });

  testWidgets('History tab opens past day view', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppRoot.termsAcceptedKey: true,
      AppRoot.privacyAcceptedKey: true,
    });
    await tester.pumpWidget(const PerfectDayApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsWidgets);
    expect(find.text('Pick day'), findsOneWidget);
    expect(find.text('Day summary'), findsOneWidget);
  });
}
