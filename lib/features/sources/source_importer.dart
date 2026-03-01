import '../today/data/today_storage.dart';
import '../today/models/day_models.dart';
import 'source_adapter.dart';

class SourceImportSummary {
  const SourceImportSummary({
    required this.importedEventCount,
    required this.touchedDayCount,
    required this.completedAt,
  });

  final int importedEventCount;
  final int touchedDayCount;
  final DateTime completedAt;
}

class SourceImporter {
  SourceImporter({
    required this.storage,
    required this.adapters,
  });

  final TodayStorage storage;
  final List<SourceAdapter> adapters;

  Future<SourceImportSummary> importForRange({
    required DateTime from,
    required DateTime to,
    required Set<SourceType> enabledSources,
  }) async {
    final List<DayRecord> records = storage.loadRecords();
    final Map<String, DayRecord> byDate = <String, DayRecord>{
      for (final DayRecord record in records) record.dateKey: record,
    };

    int importedEvents = 0;
    final Set<String> touchedDays = <String>{};

    for (final SourceAdapter adapter in adapters) {
      if (!enabledSources.contains(adapter.source)) {
        continue;
      }

      final SourceImportResult result = await adapter.importRange(
        from: from,
        to: to,
      );

      for (final DayEvent event in result.events) {
        final String dateKey = _dateKey(event.endAt);
        final DayRecord existing = byDate[dateKey] ??
            DayRecord(
              dateKey: dateKey,
              rating: 7,
              events: const <DayEvent>[],
              checkIns: const <DayCheckIn>[],
              notes: const <DayNote>[],
            );

        final bool alreadyExists = existing.events.any((e) => e.id == event.id);
        if (alreadyExists) {
          continue;
        }

        final List<DayEvent> updatedEvents = List<DayEvent>.from(existing.events)
          ..add(event);
        byDate[dateKey] = existing.copyWith(events: updatedEvents);
        importedEvents++;
        touchedDays.add(dateKey);
      }
    }

    final List<DayRecord> updated = byDate.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    await storage.saveRecords(updated);

    return SourceImportSummary(
      importedEventCount: importedEvents,
      touchedDayCount: touchedDays.length,
      completedAt: DateTime.now(),
    );
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
