import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/features/today/today_view_model.dart';
import 'package:perfect_day/features/trends/trends_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads with data after today model seeds records', () async {
    await TodayViewModel.create();
    final TrendsViewModel trends = await TrendsViewModel.create();

    expect(trends.hasData, isTrue);
    expect(trends.trendPoints, isNotEmpty);
    expect(trends.averageRating, greaterThan(0));
  });

  test('range selector updates active range', () async {
    await TodayViewModel.create();
    final TrendsViewModel trends = await TrendsViewModel.create();

    trends.setRange(TrendRange.month);

    expect(trends.range, TrendRange.month);
    expect(trends.rangeLabel, 'Month');
  });
}
