import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/day_models.dart';

class TodayStorage {
  TodayStorage(this._prefs);

  static const String _key = 'perfect_day_records_v1';

  final SharedPreferences _prefs;

  static Future<TodayStorage> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return TodayStorage(prefs);
  }

  List<DayRecord> loadRecords() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <DayRecord>[];
    }

    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((json) => DayRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecords(List<DayRecord> records) async {
    final String payload = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _prefs.setString(_key, payload);
  }
}
