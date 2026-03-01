import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/features/history/history_view_model.dart';
import 'package:perfect_day/features/today/today_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads records and exposes selected day summary', () async {
    await TodayViewModel.create();
    final HistoryViewModel history = await HistoryViewModel.create();

    expect(history.records, isNotEmpty);
    expect(history.selectedRecord, isNotNull);
    expect(history.selectedRating, isNot('N/A'));
    expect(history.timeBreakdown, isNotEmpty);
  });

  test('can select a different day', () async {
    await TodayViewModel.create();
    final HistoryViewModel history = await HistoryViewModel.create();

    if (history.records.length < 2) {
      return;
    }

    final String secondDate = history.records[1].dateKey;
    history.selectDate(secondDate);

    expect(history.selectedDateKey, secondDate);
  });

  test('date key conversion maps calendar day to stored format', () async {
    await TodayViewModel.create();
    final HistoryViewModel history = await HistoryViewModel.create();

    final DateTime date = DateTime(2026, 3, 1);
    expect(history.dateKeyFromDate(date), '2026-03-01');
  });
}
