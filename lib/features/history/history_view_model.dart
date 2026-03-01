import 'package:flutter/foundation.dart';

import '../today/data/today_storage.dart';
import '../today/models/day_models.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel._(this._storage);

  final TodayStorage _storage;

  bool isLoading = true;
  List<DayRecord> records = <DayRecord>[];
  String? selectedDateKey;

  static Future<HistoryViewModel> create() async {
    final TodayStorage storage = await TodayStorage.create();
    final HistoryViewModel viewModel = HistoryViewModel._(storage);
    await viewModel._load();
    return viewModel;
  }

  Future<void> _load() async {
    records = _storage.loadRecords()..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    if (records.isNotEmpty) {
      selectedDateKey = records.first.dateKey;
    }
    isLoading = false;
    notifyListeners();
  }

  DayRecord? get selectedRecord {
    if (selectedDateKey == null) {
      return null;
    }
    for (final DayRecord record in records) {
      if (record.dateKey == selectedDateKey) {
        return record;
      }
    }
    return null;
  }

  void selectDate(String dateKey) {
    if (selectedDateKey == dateKey) {
      return;
    }
    selectedDateKey = dateKey;
    notifyListeners();
  }

  List<MapEntry<String, String>> get dayOptions {
    return records.map((record) {
      final DateTime date = DateTime.parse(record.dateKey);
      return MapEntry(record.dateKey, _labelDate(date));
    }).toList();
  }

  DateTime get initialCalendarDate {
    final DayRecord? record = selectedRecord;
    if (record == null) {
      return DateTime.now();
    }
    return DateTime.parse(record.dateKey);
  }

  DateTime get firstAvailableDate {
    if (records.isEmpty) {
      return DateTime.now();
    }
    return DateTime.parse(records.last.dateKey);
  }

  DateTime get lastAvailableDate {
    if (records.isEmpty) {
      return DateTime.now();
    }
    return DateTime.parse(records.first.dateKey);
  }

  bool hasRecordForDate(DateTime date) {
    return records.any((record) => record.dateKey == dateKeyFromDate(date));
  }

  String dateKeyFromDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<MapEntry<String, String>> get timeBreakdown {
    final DayRecord? record = selectedRecord;
    if (record == null) {
      return const <MapEntry<String, String>>[];
    }

    final Map<DayDomain, int> totals = <DayDomain, int>{};
    for (final DayEvent event in record.events) {
      totals[event.domain] = (totals[event.domain] ?? 0) + event.durationMinutes;
    }

    return <MapEntry<String, String>>[
      MapEntry('Sleep', _formatMinutes(totals[DayDomain.sleep] ?? 0)),
      MapEntry('Work', _formatMinutes(totals[DayDomain.work] ?? 0)),
      MapEntry('Exercise', _formatMinutes(totals[DayDomain.exercise] ?? 0)),
      MapEntry('Social', _formatMinutes(totals[DayDomain.social] ?? 0)),
      MapEntry('Digital', _formatMinutes(totals[DayDomain.digital] ?? 0)),
    ];
  }

  String get selectedRating {
    final DayRecord? record = selectedRecord;
    if (record == null) {
      return 'N/A';
    }
    return '${record.rating.toStringAsFixed(1)}/10';
  }

  int get selectedAssessmentCount => selectedRecord?.checkIns.length ?? 0;

  int get selectedNotesCount => selectedRecord?.notes.length ?? 0;

  String get selectedDateLabel {
    final DayRecord? record = selectedRecord;
    if (record == null) {
      return 'No data for selected day';
    }
    return _labelDate(DateTime.parse(record.dateKey));
  }

  String _labelDate(DateTime date) {
    const List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }
    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;
    if (hours == 0) {
      return '${remaining}m';
    }
    if (remaining == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remaining}m';
  }
}
