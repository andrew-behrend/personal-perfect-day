import '../today/models/day_models.dart';

enum SourceType {
  health,
  calendar,
  screenTime,
}

class SourceConnectionState {
  const SourceConnectionState({
    required this.type,
    required this.connected,
    required this.lastSyncAt,
  });

  final SourceType type;
  final bool connected;
  final DateTime? lastSyncAt;
}

class SourceImportResult {
  const SourceImportResult({
    required this.source,
    required this.events,
  });

  final SourceType source;
  final List<DayEvent> events;
}

abstract class SourceAdapter {
  SourceType get source;

  Future<SourceConnectionState> connectionState();

  Future<SourceImportResult> importRange({
    required DateTime from,
    required DateTime to,
  });
}
