import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sources/source_adapter.dart';
import '../sources/source_importer.dart';
import '../sources/source_registry.dart';
import '../sources/sync_status_store.dart';
import '../today/data/today_storage.dart';

class SourceToggle {
  const SourceToggle({
    required this.key,
    required this.name,
    required this.detail,
    required this.enabled,
  });

  final String key;
  final String name;
  final String detail;
  final bool enabled;

  SourceToggle copyWith({bool? enabled}) {
    return SourceToggle(
      key: key,
      name: name,
      detail: detail,
      enabled: enabled ?? this.enabled,
    );
  }
}

enum ImportLookback {
  days7,
  days30,
  days90,
}

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel._(this._prefs, this._importer, this._statusStore);

  static const String healthKey = 'source_health_enabled_v1';
  static const String calendarKey = 'source_calendar_enabled_v1';
  static const String screenTimeKey = 'source_screentime_enabled_v1';
  static const String lookbackKey = 'source_import_lookback_v1';
  static const String autoSyncOnOpenKey = 'source_auto_sync_on_open_v1';

  final SharedPreferences _prefs;
  final SourceImporter _importer;
  final SyncStatusStore _statusStore;

  List<SourceToggle> connectedSources = const <SourceToggle>[];
  final Map<SourceType, SourceConnectionState> sourceStates =
      <SourceType, SourceConnectionState>{};
  ImportLookback lookback = ImportLookback.days30;
  bool autoSyncOnOpen = false;
  bool isSyncing = false;
  bool isRequestingHealthAccess = false;
  String? syncMessage;
  DateTime? lastSyncAt;

  static Future<SettingsViewModel> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final TodayStorage storage = await TodayStorage.create();
    final SyncStatusStore statusStore = await SyncStatusStore.create();
    final SourceImporter importer = SourceImporter(
      storage: storage,
      adapters: buildSourceAdapters(),
    );

    final SettingsViewModel model =
        SettingsViewModel._(prefs, importer, statusStore);
    model._load();
    await model.refreshSourceStates();
    return model;
  }

  void _load() {
    connectedSources = <SourceToggle>[
      SourceToggle(
        key: healthKey,
        name: 'Apple Health',
        detail: 'Sleep, movement, resting heart rate',
        enabled: _prefs.getBool(healthKey) ?? true,
      ),
      SourceToggle(
        key: calendarKey,
        name: 'Calendar',
        detail: 'Work blocks and meetings',
        enabled: _prefs.getBool(calendarKey) ?? true,
      ),
      SourceToggle(
        key: screenTimeKey,
        name: 'Screen Time',
        detail: 'Digital consumption',
        enabled: _prefs.getBool(screenTimeKey) ?? true,
      ),
    ];

    final String? storedLookback = _prefs.getString(lookbackKey);
    switch (storedLookback) {
      case 'days7':
        lookback = ImportLookback.days7;
      case 'days90':
        lookback = ImportLookback.days90;
      case 'days30':
      default:
        lookback = ImportLookback.days30;
    }

    autoSyncOnOpen = _prefs.getBool(autoSyncOnOpenKey) ?? false;
    final int? lastSyncMs = _statusStore.lastSyncAtMs;
    if (lastSyncMs != null) {
      lastSyncAt = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
    syncMessage = _statusStore.lastSyncSummary;

    notifyListeners();
  }

  List<SourceToggle> get availableSources {
    return const <SourceToggle>[
      SourceToggle(
        key: 'location',
        name: 'Location',
        detail: 'Home vs away context',
        enabled: false,
      ),
      SourceToggle(
        key: 'music',
        name: 'Music listening',
        detail: 'Ambient context for day quality',
        enabled: false,
      ),
      SourceToggle(
        key: 'notes',
        name: 'Micro-notes sentiment',
        detail: 'Emotion context from quick notes',
        enabled: false,
      ),
    ];
  }

  String get importPolicySummary {
    return 'Import window: ${lookbackLabel(lookback)}';
  }

  String get lastSyncLabel {
    if (lastSyncAt == null) {
      return 'No sync yet';
    }
    final DateTime value = lastSyncAt!;
    final int hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour >= 12 ? 'PM' : 'AM';
    return 'Last sync: ${value.month}/${value.day} $hour:$minute $period';
  }

  String lookbackLabel(ImportLookback value) {
    switch (value) {
      case ImportLookback.days7:
        return 'Last 7 days';
      case ImportLookback.days30:
        return 'Last 30 days';
      case ImportLookback.days90:
        return 'Last 90 days';
    }
  }

  int lookbackDays(ImportLookback value) {
    switch (value) {
      case ImportLookback.days7:
        return 7;
      case ImportLookback.days30:
        return 30;
      case ImportLookback.days90:
        return 90;
    }
  }

  Future<void> setSourceEnabled(String key, bool enabled) async {
    await _prefs.setBool(key, enabled);
    connectedSources = connectedSources
        .map(
          (source) => source.key == key
              ? source.copyWith(enabled: enabled)
              : source,
        )
        .toList();
    notifyListeners();
  }

  Future<void> setLookback(ImportLookback value) async {
    lookback = value;
    await _prefs.setString(lookbackKey, value.name);
    notifyListeners();
  }

  Future<void> setAutoSyncOnOpen(bool value) async {
    autoSyncOnOpen = value;
    await _prefs.setBool(autoSyncOnOpenKey, value);
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (isSyncing) {
      return;
    }

    isSyncing = true;
    syncMessage = null;
    notifyListeners();

    try {
      final DateTime to = DateTime.now();
      final DateTime from = to.subtract(
        Duration(days: lookbackDays(lookback)),
      );

      final SourceImportSummary summary = await _importer.importForRange(
        from: from,
        to: to,
        enabledSources: _enabledSourceTypes(),
      );

      await _statusStore.write(summary);
      lastSyncAt = summary.completedAt;
      syncMessage = _statusStore.lastSyncSummary;
    } catch (_) {
      syncMessage = 'Sync failed. Please try again.';
      await _statusStore.writeFailure(syncMessage!);
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> refreshSourceStates() async {
    sourceStates.clear();
    for (final SourceAdapter adapter in _importer.adapters) {
      final SourceConnectionState state = await adapter.connectionState();
      sourceStates[adapter.source] = state;
    }
    notifyListeners();
  }

  Future<void> requestHealthAccess() async {
    if (isRequestingHealthAccess) {
      return;
    }

    isRequestingHealthAccess = true;
    notifyListeners();

    try {
      bool granted = false;
      for (final SourceAdapter adapter in _importer.adapters) {
        if (adapter.source != SourceType.health) {
          continue;
        }
        if (adapter is AuthorizationSourceAdapter) {
          final AuthorizationSourceAdapter authAdapter =
              adapter as AuthorizationSourceAdapter;
          granted = await authAdapter.requestAuthorization();
        }
      }
      syncMessage = granted
          ? 'Health access granted.'
          : 'Health access not granted.';
      await refreshSourceStates();
    } finally {
      isRequestingHealthAccess = false;
      notifyListeners();
    }
  }

  String sourceStateLabel(String key) {
    final SourceType? type = _sourceTypeFromKey(key);
    if (type == null) {
      return 'Unknown';
    }
    final SourceConnectionState? state = sourceStates[type];
    if (state == null) {
      return 'Checking...';
    }
    return state.connected ? 'Connected' : 'Not connected';
  }

  Set<SourceType> _enabledSourceTypes() {
    final Set<SourceType> result = <SourceType>{};
    for (final SourceToggle source in connectedSources) {
      if (!source.enabled) {
        continue;
      }
      if (source.key == healthKey) {
        result.add(SourceType.health);
      } else if (source.key == calendarKey) {
        result.add(SourceType.calendar);
      } else if (source.key == screenTimeKey) {
        result.add(SourceType.screenTime);
      }
    }
    return result;
  }

  SourceType? _sourceTypeFromKey(String key) {
    if (key == healthKey) {
      return SourceType.health;
    }
    if (key == calendarKey) {
      return SourceType.calendar;
    }
    if (key == screenTimeKey) {
      return SourceType.screenTime;
    }
    return null;
  }

  static int lookbackDaysFromStored(String? stored) {
    switch (stored) {
      case 'days7':
        return 7;
      case 'days90':
        return 90;
      case 'days30':
      default:
        return 30;
    }
  }
}
