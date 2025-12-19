// lib/growth/growth_entry.dart

class GrowthEntry {
  final String id;
  final DateTime date;

  /// grams
  final int? weightGr;

  /// cm
  final double? lengthCm;

  /// cm
  final double? headCm;

  const GrowthEntry({
    required this.id,
    required this.date,
    this.weightGr,
    this.lengthCm,
    this.headCm,
  });

  /// UI kolaylığı: kg olarak gösterim (null-safe)
  double? get weightKg => weightGr == null ? null : weightGr! / 1000.0;

  /// Tarih normalize (saat/dakika/saniye sıfır) - aynı gün kayıtlarını tutarlı işler
  DateTime get day => DateTime(date.year, date.month, date.day);

  GrowthEntry copyWith({
    String? id,
    DateTime? date,
    int? weightGr,
    double? lengthCm,
    double? headCm,
  }) {
    return GrowthEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightGr: weightGr ?? this.weightGr,
      lengthCm: lengthCm ?? this.lengthCm,
      headCm: headCm ?? this.headCm,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'weightGr': weightGr,
    'lengthCm': lengthCm,
    'headCm': headCm,
  };

  factory GrowthEntry.fromMap(Map<String, dynamic> map) {
    return GrowthEntry(
      id: (map['id'] ?? '').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      weightGr: _asIntNullable(map['weightGr']),
      lengthCm: _asDoubleNullable(map['lengthCm']),
      headCm: _asDoubleNullable(map['headCm']),
    );
  }

  /// Opsiyonel: Input doğrulama / temizlik için güvenli factory.
  /// Negatif değerleri ve anlamsız 0'ları null'a çevirir.
  factory GrowthEntry.sanitized({
    required String id,
    required DateTime date,
    int? weightGr,
    double? lengthCm,
    double? headCm,
  }) {
    int? wg = weightGr;
    double? lc = lengthCm;
    double? hc = headCm;

    if (wg != null && wg <= 0) wg = null;
    if (lc != null && lc <= 0) lc = null;
    if (hc != null && hc <= 0) hc = null;

    // Çok uzun ondalıklar varsa UI/serialize tutarlılığı için kırp (opsiyonel ama faydalı)
    lc = lc == null ? null : _round1(lc);
    hc = hc == null ? null : _round1(hc);

    return GrowthEntry(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      weightGr: wg,
      lengthCm: lc,
      headCm: hc,
    );
  }

  static int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  static double? _asDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static double _round1(double v) => (v * 10).round() / 10.0;

  @override
  String toString() =>
      'GrowthEntry(id: $id, date: ${date.toIso8601String()}, weightGr: $weightGr, lengthCm: $lengthCm, headCm: $headCm)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GrowthEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
