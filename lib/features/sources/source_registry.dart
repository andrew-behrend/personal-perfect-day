import 'healthkit_source_adapter.dart';
import 'mock_source_adapters.dart';
import 'source_adapter.dart';

List<SourceAdapter> buildSourceAdapters() {
  return <SourceAdapter>[
    HealthKitSourceAdapter(),
    MockCalendarSourceAdapter(),
    MockScreenTimeSourceAdapter(),
  ];
}
