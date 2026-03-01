import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perfect_day/features/sources/mock_source_adapters.dart';
import 'package:perfect_day/features/sources/source_adapter.dart';
import 'package:perfect_day/features/sources/source_importer.dart';
import 'package:perfect_day/features/today/data/today_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('imports events into local day records', () async {
    final TodayStorage storage = await TodayStorage.create();
    final SourceImporter importer = SourceImporter(
      storage: storage,
      adapters: <SourceAdapter>[
        MockHealthSourceAdapter(),
        MockCalendarSourceAdapter(),
        MockScreenTimeSourceAdapter(),
      ],
    );

    final DateTime now = DateTime.now();
    final SourceImportSummary summary = await importer.importForRange(
      from: now.subtract(const Duration(days: 7)),
      to: now,
      enabledSources: <SourceType>{
        SourceType.health,
        SourceType.calendar,
        SourceType.screenTime,
      },
    );

    final records = storage.loadRecords();
    expect(summary.importedEventCount, greaterThan(0));
    expect(records, isNotEmpty);
    expect(records.last.events, isNotEmpty);
  });
}
