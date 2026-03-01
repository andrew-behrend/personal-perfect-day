import 'package:flutter/foundation.dart';

import 'data/today_storage.dart';
import 'models/day_models.dart';

class TodayViewModel extends ChangeNotifier {
  TodayViewModel._(this._storage);

  final TodayStorage _storage;

  final List<DayRecord> _records = <DayRecord>[];

  bool isInitializing = true;
  bool isSaving = false;
  bool isSaved = false;
  double rating = 7;

  DayRecord? _today;

  static Future<TodayViewModel> create() async {
    final TodayStorage storage = await TodayStorage.create();
    final TodayViewModel viewModel = TodayViewModel._(storage);
    await viewModel._initialize();
    return viewModel;
  }

  Future<void> _initialize() async {
    _records.addAll(_storage.loadRecords());
    final String todayKey = _dateKey(DateTime.now());

    if (_records.isEmpty) {
      _records.addAll(_seedRecords(todayKey));
      await _storage.saveRecords(_records);
    }

    DayRecord? existingToday;
    for (final DayRecord record in _records) {
      if (record.dateKey == todayKey) {
        existingToday = record;
        break;
      }
    }

    _today =
        existingToday ??
        DayRecord(dateKey: todayKey, rating: 7, events: _defaultTodayEvents());

    _upsertToday(_today!);
    rating = _today!.rating;
    isInitializing = false;
    notifyListeners();
  }

  void updateRating(double value) {
    rating = value;
    isSaved = false;
    _today = _today?.copyWith(rating: value);
    if (_today != null) {
      _upsertToday(_today!);
    }
    notifyListeners();
  }

  Future<void> saveRating() async {
    if (isSaving || isSaved || _today == null) {
      return;
    }

    isSaving = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    isSaving = false;
    isSaved = true;
    _today = _today!.copyWith(rating: rating);
    _upsertToday(_today!);
    await _storage.saveRecords(_records);
    notifyListeners();
  }

  Future<void> addQuickEvent(DayDomain domain, int minutes) async {
    if (_today == null || minutes <= 0) {
      return;
    }

    final DateTime endAt = DateTime.now();
    final DateTime startAt = endAt.subtract(Duration(minutes: minutes));
    final DayEvent event = DayEvent(
      id: '${domain.name}-${endAt.microsecondsSinceEpoch}',
      domain: domain,
      startAt: startAt,
      endAt: endAt,
    );
    final List<DayEvent> updatedEvents = List<DayEvent>.from(_today!.events)
      ..add(event);
    _today = _today!.copyWith(events: updatedEvents);
    _upsertToday(_today!);
    await _storage.saveRecords(_records);
    notifyListeners();
  }

  List<String> get atAGlance {
    final Map<DayDomain, int> totals = _durationByDomain();
    return <String>[
      '${_formatMinutes(totals[DayDomain.sleep] ?? 0)} sleep',
      '${_formatMinutes(totals[DayDomain.exercise] ?? 0)} exercise',
      '${_formatMinutes(totals[DayDomain.meetings] ?? 0)} meetings',
      '${_formatMinutes(totals[DayDomain.digital] ?? 0)} digital consumption',
    ];
  }

  List<MapEntry<String, String>> get timeBreakdown {
    final Map<DayDomain, int> totals = _durationByDomain();
    return <MapEntry<String, String>>[
      MapEntry('Sleep', _formatMinutes(totals[DayDomain.sleep] ?? 0)),
      MapEntry('Work', _formatMinutes(totals[DayDomain.work] ?? 0)),
      MapEntry('Exercise', _formatMinutes(totals[DayDomain.exercise] ?? 0)),
      MapEntry('Social', _formatMinutes(totals[DayDomain.social] ?? 0)),
      MapEntry(
        'Away from home',
        _formatMinutes(totals[DayDomain.awayFromHome] ?? 0),
      ),
    ];
  }

  List<String> get notables {
    final Map<DayDomain, int> totals = _durationByDomain();
    final List<String> result = <String>[];

    if ((totals[DayDomain.digital] ?? 0) >= 100) {
      result.add('Above-average digital usage');
    }
    if ((totals[DayDomain.exercise] ?? 0) >= 45) {
      result.add('Strong movement day');
    }
    if ((totals[DayDomain.sleep] ?? 0) < 420) {
      result.add('Sleep came in below 7 hours');
    }
    if (result.isEmpty) {
      result.add('Stable day with no major outliers');
    }

    return result;
  }

  List<MapEntry<String, String>> get recentDays {
    final String todayKey = _today?.dateKey ?? _dateKey(DateTime.now());
    final List<DayRecord> prior = _records
        .where((record) => record.dateKey != todayKey)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

    return prior.take(5).map((record) {
      final DateTime date = DateTime.parse(record.dateKey);
      final int exerciseMinutes = _durationFor(record, DayDomain.exercise);
      return MapEntry(
        _shortDate(date),
        'Rating ${record.rating.toStringAsFixed(1)} • Exercise ${_formatMinutes(exerciseMinutes)}',
      );
    }).toList();
  }

  List<String> get insights {
    final List<DayRecord> dataset = List<DayRecord>.from(_records);
    if (dataset.length < 3) {
      return <String>['Add a few more days to unlock pattern insights'];
    }

    final List<DayRecord> activeDays = dataset
        .where((record) => _durationFor(record, DayDomain.exercise) >= 45)
        .toList();
    final List<DayRecord> lowActivityDays = dataset
        .where((record) => _durationFor(record, DayDomain.exercise) < 45)
        .toList();

    final List<String> lines = <String>[];
    if (activeDays.isNotEmpty && lowActivityDays.isNotEmpty) {
      lines.add(
        'Exercise days (45m+) average ${_avgRating(activeDays).toStringAsFixed(1)} vs ${_avgRating(lowActivityDays).toStringAsFixed(1)} on lower-activity days',
      );
    }

    final List<DayRecord> strongSleepDays = dataset
        .where((record) => _durationFor(record, DayDomain.sleep) >= 420)
        .toList();
    if (strongSleepDays.isNotEmpty && strongSleepDays.length < dataset.length) {
      lines.add(
        'Days with 7h+ sleep average ${_avgRating(strongSleepDays).toStringAsFixed(1)}',
      );
    }

    return lines.isEmpty
        ? <String>['Patterns are still emerging from your logged days']
        : lines;
  }

  List<MapEntry<String, int>> get quickAddOptions {
    return <MapEntry<String, int>>[
      const MapEntry<String, int>('Add 30m Work', 30),
      const MapEntry<String, int>('Add 20m Exercise', 20),
      const MapEntry<String, int>('Add 45m Social', 45),
      const MapEntry<String, int>('Add 30m Digital', 30),
    ];
  }

  Future<void> addQuickEventFromLabel(String label, int minutes) async {
    final DayDomain domain;
    if (label.contains('Work')) {
      domain = DayDomain.work;
    } else if (label.contains('Exercise')) {
      domain = DayDomain.exercise;
    } else if (label.contains('Social')) {
      domain = DayDomain.social;
    } else {
      domain = DayDomain.digital;
    }
    await addQuickEvent(domain, minutes);
  }

  void _upsertToday(DayRecord today) {
    final int index = _records.indexWhere((record) => record.dateKey == today.dateKey);
    if (index == -1) {
      _records.add(today);
    } else {
      _records[index] = today;
    }
  }

  Map<DayDomain, int> _durationByDomain() {
    if (_today == null) {
      return <DayDomain, int>{};
    }

    final Map<DayDomain, int> totals = <DayDomain, int>{};
    for (final DayEvent event in _today!.events) {
      totals[event.domain] = (totals[event.domain] ?? 0) + event.durationMinutes;
    }
    return totals;
  }

  int _durationFor(DayRecord record, DayDomain domain) {
    return record.events
        .where((event) => event.domain == domain)
        .fold<int>(0, (sum, event) => sum + event.durationMinutes);
  }

  double _avgRating(List<DayRecord> records) {
    final double total = records.fold<double>(
      0,
      (sum, record) => sum + record.rating,
    );
    return total / records.length;
  }

  List<DayRecord> _seedRecords(String todayKey) {
    final DateTime today = DateTime.parse(todayKey);
    return <DayRecord>[
      DayRecord(
        dateKey: _dateKey(today.subtract(const Duration(days: 3))),
        rating: 8,
        events: <DayEvent>[
          _seedEvent(DayDomain.sleep, 460),
          _seedEvent(DayDomain.work, 450),
          _seedEvent(DayDomain.exercise, 55),
          _seedEvent(DayDomain.social, 40),
          _seedEvent(DayDomain.digital, 70),
        ],
      ),
      DayRecord(
        dateKey: _dateKey(today.subtract(const Duration(days: 2))),
        rating: 6,
        events: <DayEvent>[
          _seedEvent(DayDomain.sleep, 360),
          _seedEvent(DayDomain.work, 510),
          _seedEvent(DayDomain.exercise, 10),
          _seedEvent(DayDomain.social, 20),
          _seedEvent(DayDomain.digital, 130),
        ],
      ),
      DayRecord(
        dateKey: _dateKey(today.subtract(const Duration(days: 1))),
        rating: 7,
        events: <DayEvent>[
          _seedEvent(DayDomain.sleep, 430),
          _seedEvent(DayDomain.work, 470),
          _seedEvent(DayDomain.exercise, 30),
          _seedEvent(DayDomain.social, 35),
          _seedEvent(DayDomain.digital, 90),
        ],
      ),
      DayRecord(
        dateKey: todayKey,
        rating: 7,
        events: _defaultTodayEvents(),
      ),
    ];
  }

  List<DayEvent> _defaultTodayEvents() {
    return <DayEvent>[
      _seedEvent(DayDomain.sleep, 432),
      _seedEvent(DayDomain.exercise, 52),
      _seedEvent(DayDomain.meetings, 150),
      _seedEvent(DayDomain.work, 480),
      _seedEvent(DayDomain.social, 45),
      _seedEvent(DayDomain.digital, 107),
      _seedEvent(DayDomain.awayFromHome, 180),
    ];
  }

  DayEvent _seedEvent(DayDomain domain, int minutes) {
    final DateTime endAt = DateTime.now();
    final DateTime startAt = endAt.subtract(Duration(minutes: minutes));
    return DayEvent(
      id: '${domain.name}-$minutes-${endAt.microsecondsSinceEpoch}',
      domain: domain,
      startAt: startAt,
      endAt: endAt,
      source: 'mock',
    );
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

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _shortDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
