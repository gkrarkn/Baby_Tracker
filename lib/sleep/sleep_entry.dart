class SleepEntry {
  final String id;
  final DateTime start;
  final DateTime end;

  const SleepEntry({required this.id, required this.start, required this.end});

  Duration get duration => end.difference(start);

  SleepEntry copyWith({String? id, DateTime? start, DateTime? end}) {
    return SleepEntry(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
