enum DayDomain {
  sleep,
  work,
  exercise,
  social,
  meetings,
  awayFromHome,
  digital,
  chores,
  learning,
  reflection,
}

class DayEvent {
  DayEvent({
    required this.id,
    required this.domain,
    required this.startAt,
    required this.endAt,
    this.source = 'manual',
    this.note,
  });

  final String id;
  final DayDomain domain;
  final DateTime startAt;
  final DateTime endAt;
  final String source;
  final String? note;

  int get durationMinutes =>
      endAt.difference(startAt).inMinutes.clamp(0, 1440).toInt();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'domain': domain.name,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'source': source,
      'note': note,
    };
  }

  static DayEvent fromJson(Map<String, dynamic> json) {
    return DayEvent(
      id: json['id'] as String,
      domain: DayDomain.values.byName(json['domain'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      source: json['source'] as String? ?? 'manual',
      note: json['note'] as String?,
    );
  }
}

class DayRecord {
  DayRecord({
    required this.dateKey,
    required this.rating,
    required this.events,
    this.checkIns = const <DayCheckIn>[],
    this.notes = const <DayNote>[],
  });

  final String dateKey;
  final double rating;
  final List<DayEvent> events;
  final List<DayCheckIn> checkIns;
  final List<DayNote> notes;

  DayRecord copyWith({
    String? dateKey,
    double? rating,
    List<DayEvent>? events,
    List<DayCheckIn>? checkIns,
    List<DayNote>? notes,
  }) {
    return DayRecord(
      dateKey: dateKey ?? this.dateKey,
      rating: rating ?? this.rating,
      events: events ?? this.events,
      checkIns: checkIns ?? this.checkIns,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'rating': rating,
      'events': events.map((event) => event.toJson()).toList(),
      'checkIns': checkIns.map((checkIn) => checkIn.toJson()).toList(),
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }

  static DayRecord fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEvents = json['events'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawCheckIns =
        json['checkIns'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawNotes = json['notes'] as List<dynamic>? ?? <dynamic>[];

    return DayRecord(
      dateKey: json['dateKey'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 7,
      events: rawEvents
          .map((raw) => DayEvent.fromJson(raw as Map<String, dynamic>))
          .toList(),
      checkIns: rawCheckIns
          .map((raw) => DayCheckIn.fromJson(raw as Map<String, dynamic>))
          .toList(),
      notes: rawNotes
          .map((raw) => DayNote.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DayCheckIn {
  DayCheckIn({
    required this.at,
    required this.rating,
  });

  final DateTime at;
  final double rating;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'at': at.toIso8601String(),
      'rating': rating,
    };
  }

  static DayCheckIn fromJson(Map<String, dynamic> json) {
    return DayCheckIn(
      at: DateTime.parse(json['at'] as String),
      rating: (json['rating'] as num).toDouble(),
    );
  }
}

class DayNote {
  DayNote({
    required this.at,
    required this.text,
    required this.feeling,
  });

  final DateTime at;
  final String text;
  final int feeling;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'at': at.toIso8601String(),
      'text': text,
      'feeling': feeling,
    };
  }

  static DayNote fromJson(Map<String, dynamic> json) {
    return DayNote(
      at: DateTime.parse(json['at'] as String),
      text: json['text'] as String,
      feeling: (json['feeling'] as num).toInt(),
    );
  }
}
