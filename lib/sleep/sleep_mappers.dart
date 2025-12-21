import 'sleep_entry.dart';

class SleepMappers {
  static Map<String, dynamic> toMap(SleepEntry e) => {
    'id': e.id,
    'start': e.start.toIso8601String(),
    'end': e.end.toIso8601String(),
  };

  static SleepEntry fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: (map['id'] ?? '').toString(),
      start:
          DateTime.tryParse((map['start'] ?? '').toString()) ?? DateTime.now(),
      end: DateTime.tryParse((map['end'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
