import '../today/models/day_models.dart';
import 'source_adapter.dart';

class MockHealthSourceAdapter implements SourceAdapter {
  @override
  SourceType get source => SourceType.health;

  @override
  Future<SourceConnectionState> connectionState() async {
    return SourceConnectionState(
      type: source,
      connected: true,
      lastSyncAt: DateTime.now().subtract(const Duration(hours: 3)),
    );
  }

  @override
  Future<SourceImportResult> importRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime end = to;
    final DateTime start = end.subtract(const Duration(minutes: 50));
    return SourceImportResult(
      source: source,
      events: <DayEvent>[
        DayEvent(
          id: 'health-${end.microsecondsSinceEpoch}',
          domain: DayDomain.exercise,
          startAt: start,
          endAt: end,
          source: 'health_mock',
        ),
      ],
    );
  }
}

class MockCalendarSourceAdapter implements SourceAdapter {
  @override
  SourceType get source => SourceType.calendar;

  @override
  Future<SourceConnectionState> connectionState() async {
    return SourceConnectionState(
      type: source,
      connected: true,
      lastSyncAt: DateTime.now().subtract(const Duration(hours: 5)),
    );
  }

  @override
  Future<SourceImportResult> importRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime meetingStart = to.subtract(const Duration(hours: 4));
    final DateTime meetingEnd = to.subtract(const Duration(hours: 2, minutes: 30));
    return SourceImportResult(
      source: source,
      events: <DayEvent>[
        DayEvent(
          id: 'calendar-${meetingStart.millisecondsSinceEpoch}',
          domain: DayDomain.meetings,
          startAt: meetingStart,
          endAt: meetingEnd,
          source: 'calendar_mock',
        ),
      ],
    );
  }
}

class MockScreenTimeSourceAdapter implements SourceAdapter {
  @override
  SourceType get source => SourceType.screenTime;

  @override
  Future<SourceConnectionState> connectionState() async {
    return SourceConnectionState(
      type: source,
      connected: true,
      lastSyncAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  @override
  Future<SourceImportResult> importRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime start = to.subtract(const Duration(hours: 1, minutes: 20));
    return SourceImportResult(
      source: source,
      events: <DayEvent>[
        DayEvent(
          id: 'screentime-${start.millisecondsSinceEpoch}',
          domain: DayDomain.digital,
          startAt: start,
          endAt: to,
          source: 'screentime_mock',
        ),
      ],
    );
  }
}
