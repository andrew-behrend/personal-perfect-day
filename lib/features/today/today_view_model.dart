import 'package:flutter/foundation.dart';

import 'data/today_storage.dart';
import 'models/day_models.dart';

class QuickAddAction {
  const QuickAddAction({
    required this.label,
    required this.domain,
    required this.minutes,
  });

  final String label;
  final DayDomain domain;
  final int minutes;
}

class SourceStatus {
  const SourceStatus({
    required this.name,
    required this.state,
    required this.detail,
  });

  final String name;
  final String state;
  final String detail;
}

class TodayViewModel extends ChangeNotifier {
  TodayViewModel._(this._storage);

  final TodayStorage _storage;

  final List<DayRecord> _records = <DayRecord>[];

  bool isInitializing = true;
  bool isSaving = false;
  bool isAddingEvent = false;
  bool isAddingNote = false;
  bool isSaved = false;
  double rating = 7;
  String? lastEventMessage;
  String? lastNoteMessage;

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

  Future<void> addQuickAssessment({double? withRating}) async {
    if (_today == null || isSaving) {
      return;
    }

    final double assessmentRating = withRating?.clamp(1, 10).toDouble() ?? rating;
    final DayCheckIn checkIn = DayCheckIn(
      at: DateTime.now(),
      rating: assessmentRating,
    );
    final List<DayCheckIn> updatedCheckIns = List<DayCheckIn>.from(
      _today!.checkIns,
    )..add(checkIn);

    _today = _today!.copyWith(checkIns: updatedCheckIns);
    _upsertToday(_today!);
    await _storage.saveRecords(_records);
    notifyListeners();
  }

  double get pulseScore {
    if (_today == null || _today!.checkIns.isEmpty) {
      return rating;
    }

    final double sum = _today!.checkIns.fold<double>(
      rating,
      (total, checkIn) => total + checkIn.rating,
    );
    return sum / (_today!.checkIns.length + 1);
  }

  List<MapEntry<String, String>> get quickAssessments {
    if (_today == null || _today!.checkIns.isEmpty) {
      return <MapEntry<String, String>>[];
    }

    final List<DayCheckIn> sorted = List<DayCheckIn>.from(_today!.checkIns)
      ..sort((a, b) => b.at.compareTo(a.at));

    return sorted.take(5).map((checkIn) {
      return MapEntry(
        _timeLabel(checkIn.at),
        'Rated ${checkIn.rating.round()}/10',
      );
    }).toList();
  }

  List<MapEntry<String, String>> get recentNotes {
    if (_today == null || _today!.notes.isEmpty) {
      return <MapEntry<String, String>>[];
    }

    final List<DayNote> sorted = List<DayNote>.from(_today!.notes)
      ..sort((a, b) => b.at.compareTo(a.at));

    return sorted.take(4).map((note) {
      final String text = note.text.length > 42
          ? '${note.text.substring(0, 42)}...'
          : note.text;
      return MapEntry(
        _timeLabel(note.at),
        '$text • Feeling ${note.feeling}/5',
      );
    }).toList();
  }

  Future<void> addQuickEvent(DayDomain domain, int minutes) async {
    if (_today == null || minutes <= 0 || isAddingEvent) {
      return;
    }

    isAddingEvent = true;
    notifyListeners();

    try {
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
      lastEventMessage =
          'Added ${_formatMinutes(minutes)} ${_domainLabel(domain)}';
    } finally {
      isAddingEvent = false;
      notifyListeners();
    }
  }

  Future<void> addMicroNote({
    required String text,
    required int feeling,
  }) async {
    final String trimmed = text.trim();
    if (_today == null || trimmed.isEmpty || isAddingNote) {
      return;
    }

    isAddingNote = true;
    notifyListeners();

    try {
      final DayNote note = DayNote(
        at: DateTime.now(),
        text: trimmed,
        feeling: feeling.clamp(1, 5),
      );
      final List<DayNote> updatedNotes = List<DayNote>.from(_today!.notes)
        ..add(note);
      _today = _today!.copyWith(notes: updatedNotes);
      _upsertToday(_today!);
      await _storage.saveRecords(_records);
      lastNoteMessage = 'Note saved';
    } finally {
      isAddingNote = false;
      notifyListeners();
    }
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

  List<SourceStatus> get sourceStatuses {
    return const <SourceStatus>[
      SourceStatus(
        name: 'Apple Health',
        state: 'Mock connected',
        detail: 'Sleep, movement, resting heart rate',
      ),
      SourceStatus(
        name: 'Calendar',
        state: 'Mock connected',
        detail: 'Work blocks and meetings',
      ),
      SourceStatus(
        name: 'Screen Time',
        state: 'Mock connected',
        detail: 'Digital consumption',
      ),
    ];
  }

  String get historicalImportNote {
    return 'Historical import policy pending (backlog): decide lookback window before live integrations.';
  }

  List<MapEntry<String, String>> get todayEvents {
    if (_today == null) {
      return <MapEntry<String, String>>[];
    }

    final List<DayEvent> sorted = List<DayEvent>.from(_today!.events)
      ..sort((a, b) => b.endAt.compareTo(a.endAt));

    return sorted.take(8).map((event) {
      final String title = _domainLabel(event.domain);
      final String detail =
          '${_formatMinutes(event.durationMinutes)} • ${_timeLabel(event.endAt)}';
      return MapEntry(title, detail);
    }).toList();
  }

  List<QuickAddAction> get quickAddOptions {
    return const <QuickAddAction>[
      QuickAddAction(
        label: 'Add 30m Work',
        domain: DayDomain.work,
        minutes: 30,
      ),
      QuickAddAction(
        label: 'Add 20m Exercise',
        domain: DayDomain.exercise,
        minutes: 20,
      ),
      QuickAddAction(
        label: 'Add 45m Social',
        domain: DayDomain.social,
        minutes: 45,
      ),
      QuickAddAction(
        label: 'Add 30m Digital',
        domain: DayDomain.digital,
        minutes: 30,
      ),
    ];
  }

  List<DayDomain> get trackableDomains {
    return const <DayDomain>[
      DayDomain.sleep,
      DayDomain.work,
      DayDomain.exercise,
      DayDomain.social,
      DayDomain.meetings,
      DayDomain.awayFromHome,
      DayDomain.digital,
      DayDomain.chores,
      DayDomain.learning,
      DayDomain.reflection,
    ];
  }

  String domainLabel(DayDomain domain) => _domainLabel(domain);

  Future<void> addQuickEventFromAction(QuickAddAction action) async {
    await addQuickEvent(action.domain, action.minutes);
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
        checkIns: const <DayCheckIn>[],
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
        checkIns: const <DayCheckIn>[],
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
        checkIns: const <DayCheckIn>[],
      ),
      DayRecord(
        dateKey: todayKey,
        rating: 7,
        events: _defaultTodayEvents(),
        checkIns: const <DayCheckIn>[],
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

  String _domainLabel(DayDomain domain) {
    switch (domain) {
      case DayDomain.sleep:
        return 'Sleep';
      case DayDomain.work:
        return 'Work';
      case DayDomain.exercise:
        return 'Exercise';
      case DayDomain.social:
        return 'Social';
      case DayDomain.meetings:
        return 'Meetings';
      case DayDomain.awayFromHome:
        return 'Away from home';
      case DayDomain.digital:
        return 'Digital';
      case DayDomain.chores:
        return 'Chores';
      case DayDomain.learning:
        return 'Learning';
      case DayDomain.reflection:
        return 'Reflection';
    }
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

  String _timeLabel(DateTime dateTime) {
    final int hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
