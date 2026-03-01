import 'package:flutter/foundation.dart';

import '../today/data/today_storage.dart';
import '../today/models/day_models.dart';

enum TrendRange { week, month, year }

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.rating,
  });

  final String label;
  final double rating;
}

class TrendsViewModel extends ChangeNotifier {
  TrendsViewModel._(this._storage);

  final TodayStorage _storage;

  bool isLoading = true;
  TrendRange range = TrendRange.week;
  List<DayRecord> _records = <DayRecord>[];

  static Future<TrendsViewModel> create() async {
    final TodayStorage storage = await TodayStorage.create();
    final TrendsViewModel viewModel = TrendsViewModel._(storage);
    await viewModel._load();
    return viewModel;
  }

  Future<void> _load() async {
    _records = _storage.loadRecords();
    isLoading = false;
    notifyListeners();
  }

  void setRange(TrendRange next) {
    if (range == next) {
      return;
    }
    range = next;
    notifyListeners();
  }

  List<DayRecord> get _filteredRecords {
    final DateTime now = DateTime.now();
    final DateTime threshold;

    switch (range) {
      case TrendRange.week:
        threshold = now.subtract(const Duration(days: 6));
      case TrendRange.month:
        threshold = now.subtract(const Duration(days: 29));
      case TrendRange.year:
        threshold = now.subtract(const Duration(days: 364));
    }

    final List<DayRecord> filtered = _records.where((record) {
      final DateTime date = DateTime.parse(record.dateKey);
      return !date.isBefore(DateTime(threshold.year, threshold.month, threshold.day));
    }).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    return filtered;
  }

  bool get hasData => _filteredRecords.isNotEmpty;

  double get averageRating {
    final List<DayRecord> records = _filteredRecords;
    if (records.isEmpty) {
      return 0;
    }
    final double sum = records.fold<double>(0, (total, record) => total + record.rating);
    return sum / records.length;
  }

  String get bestDay {
    final List<DayRecord> records = _filteredRecords;
    if (records.isEmpty) {
      return 'N/A';
    }
    final DayRecord best = records.reduce((a, b) => a.rating >= b.rating ? a : b);
    final DateTime date = DateTime.parse(best.dateKey);
    return '${_shortDate(date)} • ${best.rating.toStringAsFixed(1)}/10';
  }

  String get consistencySummary {
    final List<DayRecord> records = _filteredRecords;
    if (records.length < 2) {
      return 'Need more days to estimate consistency';
    }

    final double avg = averageRating;
    final double variance = records
            .map((r) => (r.rating - avg) * (r.rating - avg))
            .fold<double>(0, (a, b) => a + b) /
        records.length;

    if (variance < 0.8) {
      return 'Consistent rating pattern';
    }
    if (variance < 2.0) {
      return 'Moderate day-to-day variation';
    }
    return 'High variation across days';
  }

  List<TrendPoint> get trendPoints {
    return _filteredRecords.map((record) {
      final DateTime date = DateTime.parse(record.dateKey);
      return TrendPoint(
        label: _pointLabel(date),
        rating: record.rating,
      );
    }).toList();
  }

  int get assessmentCount {
    return _filteredRecords.fold<int>(
      0,
      (sum, record) => sum + record.checkIns.length,
    );
  }

  int get noteCount {
    return _filteredRecords.fold<int>(
      0,
      (sum, record) => sum + record.notes.length,
    );
  }

  String get rangeLabel {
    switch (range) {
      case TrendRange.week:
        return 'Week';
      case TrendRange.month:
        return 'Month';
      case TrendRange.year:
        return 'Year';
    }
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

  String _pointLabel(DateTime date) {
    if (range == TrendRange.year) {
      return _shortDate(date);
    }
    return '${date.month}/${date.day}';
  }
}
