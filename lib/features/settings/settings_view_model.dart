import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sources/mock_source_adapters.dart';
import '../sources/source_adapter.dart';
import '../sources/source_importer.dart';
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
  SettingsViewModel._(this._prefs, this._importer);

  static const String healthKey = 'source_health_enabled_v1';
  static const String calendarKey = 'source_calendar_enabled_v1';
  static const String screenTimeKey = 'source_screentime_enabled_v1';
  static const String lookbackKey = 'source_import_lookback_v1';
  static const String autoSyncOnOpenKey = 'source_auto_sync_on_open_v1';

  final SharedPreferences _prefs;
  final SourceImporter _importer;

  List<SourceToggle> connectedSources = const <SourceToggle>[];
  ImportLookback lookback = ImportLookback.days30;
  bool autoSyncOnOpen = false;
  bool isSyncing = false;
  String? syncMessage;

  static Future<SettingsViewModel> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final TodayStorage storage = await TodayStorage.create();
    final SourceImporter importer = SourceImporter(
      storage: storage,
      adapters: <SourceAdapter>[
        MockHealthSourceAdapter(),
        MockCalendarSourceAdapter(),
        MockScreenTimeSourceAdapter(),
      ],
    );

    final SettingsViewModel model = SettingsViewModel._(prefs, importer);
    model._load();
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

      syncMessage =
          'Synced ${summary.importedEventCount} events across ${summary.touchedDayCount} day(s).';
    } catch (_) {
      syncMessage = 'Sync failed. Please try again.';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
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
