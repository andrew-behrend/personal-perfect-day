import 'package:shared_preferences/shared_preferences.dart';

import 'source_importer.dart';

class SyncStatusStore {
  SyncStatusStore(this._prefs);

  static const String _lastSyncAtKey = 'sync_last_sync_at_ms_v1';
  static const String _lastSyncSummaryKey = 'sync_last_sync_summary_v1';

  final SharedPreferences _prefs;

  static Future<SyncStatusStore> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return SyncStatusStore(prefs);
  }

  int? get lastSyncAtMs => _prefs.getInt(_lastSyncAtKey);

  String? get lastSyncSummary => _prefs.getString(_lastSyncSummaryKey);

  Future<void> write(SourceImportSummary summary) async {
    await _prefs.setInt(_lastSyncAtKey, summary.completedAt.millisecondsSinceEpoch);
    await _prefs.setString(
      _lastSyncSummaryKey,
      'Synced ${summary.importedEventCount} events across ${summary.touchedDayCount} day(s).',
    );
  }

  Future<void> writeFailure(String message) async {
    await _prefs.setString(_lastSyncSummaryKey, message);
  }
}
