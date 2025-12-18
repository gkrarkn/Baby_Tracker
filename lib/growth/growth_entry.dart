class GrowthEntry {
  final String id;
  final DateTime date;

  /// Tek ve güvenilir kaynak
  /// UI'da kg gösterilebilir ama burada HER ZAMAN gram tutulur
  final int weightGr;

  GrowthEntry({required this.id, required this.date, required this.weightGr});

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'weightGr': weightGr,
  };

  factory GrowthEntry.fromMap(Map<String, dynamic> map) {
    return GrowthEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      weightGr: (map['weightGr'] as num).toInt(),
    );
  }
}
